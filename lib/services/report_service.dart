import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ReportReason {
  inappropriate,
  spam,
  misleading,
  copyright,
  violence,
  hateSpeech,
  other,
}

enum SystemReportCategory {
  performance,
  technicalIssue,
  featureRequest,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.misleading:
        return 'Misleading Information';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.violence:
        return 'Violence';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportReason.other,
    );
  }
}

extension SystemReportCategoryExtension on SystemReportCategory {
  String get displayName {
    switch (this) {
      case SystemReportCategory.performance:
        return 'Performance Issues';
      case SystemReportCategory.technicalIssue:
        return 'Technical Issues';
      case SystemReportCategory.featureRequest:
        return 'Feature Request';
      case SystemReportCategory.other:
        return 'Other';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  IconData get icon {
    switch (this) {
      case SystemReportCategory.performance:
        return Icons.speed;
      case SystemReportCategory.technicalIssue:
        return Icons.bug_report;
      case SystemReportCategory.featureRequest:
        return Icons.lightbulb_outline;
      case SystemReportCategory.other:
        return Icons.help_outline;
    }
  }

  static SystemReportCategory fromString(String value) {
    return SystemReportCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SystemReportCategory.other,
    );
  }
}

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Report a video
  Future<bool> reportVideo({
    required String videoId,
    required String videoTitle,
    required String videoUrl,
    required String uploaderId,
    required String uploaderName,
    required String uploaderEmail,
    required ReportReason reason,
    required String description,
    String? thumbnailUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not logged in');
        return false;
      }

      // Get reporter info
      final reporterDoc =
          await _firestore.collection('count').doc(currentUser.uid).get();

      String reporterName = 'Anonymous';
      String reporterEmail = currentUser.email ?? '';

      if (reporterDoc.exists) {
        final data = reporterDoc.data()!;
        reporterName =
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        if (reporterName.isEmpty) reporterName = 'Anonymous';
      }

      // Check if user already reported this video
      final existingReport = await _firestore
          .collection('video_reports')
          .where('videoId', isEqualTo: videoId)
          .where('reporterId', isEqualTo: currentUser.uid)
          .get();

      if (existingReport.docs.isNotEmpty) {
        print('User already reported this video');
        return false;
      }

      // Create report
      final reportData = {
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl ?? '',
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'uploaderEmail': uploaderEmail,
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reporterEmail': reporterEmail,
        'reason': reason.value,
        'reasonDisplay': reason.displayName,
        'description': description,
        'status': 'pending', // pending, reviewing, resolved, dismissed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'actionTaken': null,
        'adminNotes': '',
        'warningGiven': false,
        'videoDeleted': false,
      };

      await _firestore.collection('video_reports').add(reportData);
      print('Video reported successfully');
      return true;
    } catch (e) {
      print('Error reporting video: $e');
      return false;
    }
  }

  /// Check if current user has reported a video
  Future<bool> hasReported(String videoId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final report = await _firestore
          .collection('video_reports')
          .where('videoId', isEqualTo: videoId)
          .where('reporterId', isEqualTo: currentUser.uid)
          .get();

      return report.docs.isNotEmpty;
    } catch (e) {
      print('Error checking report status: $e');
      return false;
    }
  }

  /// Get report count for a video
  Future<int> getReportCount(String videoId) async {
    try {
      final reports = await _firestore
          .collection('video_reports')
          .where('videoId', isEqualTo: videoId)
          .get();

      return reports.docs.length;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }

  /// Stream reports for admin dashboard
  Stream<List<Map<String, dynamic>>> streamReports({String? status}) {
    Query query = _firestore
        .collection('video_reports')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Admin: Update report status
  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _firestore
          .collection('video_reports')
          .doc(reportId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  /// Admin: Delete reported video and update report
  Future<bool> deleteReportedVideo({
    required String reportId,
    required String videoId,
    String? adminNotes,
  }) async {
    try {
      // Update report
      await _firestore.collection('video_reports').doc(reportId).update({
        'status': 'resolved',
        'actionTaken': 'video_deleted',
        'videoDeleted': true,
        'adminNotes': adminNotes ?? 'Video deleted by admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Note: Actual video deletion should be handled by VideoUploadService
      // This just marks it in the report
      return true;
    } catch (e) {
      print('Error deleting reported video: $e');
      return false;
    }
  }

  /// Admin: Send warning to uploader
  Future<bool> sendWarningToUploader({
    required String reportId,
    required String uploaderId,
    required String videoTitle,
    required String reason,
    String? customMessage,
  }) async {
    try {
      // Create warning notification
      await _firestore
          .collection('count')
          .doc(uploaderId)
          .collection('notifications')
          .add({
        'type': 'warning',
        'title': 'Content Warning',
        'message': customMessage ??
            'Your video "$videoTitle" has received a warning for: $reason. Please review our community guidelines.',
        'videoTitle': videoTitle,
        'reason': reason,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update report
      await _firestore.collection('video_reports').doc(reportId).update({
        'status': 'resolved',
        'actionTaken': 'warning_sent',
        'warningGiven': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Warning sent to uploader');
      return true;
    } catch (e) {
      print('Error sending warning: $e');
      return false;
    }
  }

  /// Admin: Dismiss report
  Future<bool> dismissReport({
    required String reportId,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection('video_reports').doc(reportId).update({
        'status': 'dismissed',
        'actionTaken': 'dismissed',
        'adminNotes': adminNotes ?? 'Report dismissed - no violation found',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error dismissing report: $e');
      return false;
    }
  }

  /// Report a system issue (maintenance, performance, technical)
  Future<bool> reportSystemIssue({
    required SystemReportCategory category,
    required String title,
    required String description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not logged in');
        return false;
      }

      // Get reporter info
      final reporterDoc =
          await _firestore.collection('count').doc(currentUser.uid).get();

      String reporterName = 'Anonymous';
      String reporterEmail = currentUser.email ?? '';

      if (reporterDoc.exists) {
        final data = reporterDoc.data()!;
        reporterName =
            '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        if (reporterName.isEmpty) reporterName = 'Anonymous';
      }

      // Create system report
      final reportData = {
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reporterEmail': reporterEmail,
        'category': category.value,
        'categoryDisplay': category.displayName,
        'title': title,
        'description': description,
        'status': 'pending', // pending, reviewing, resolved, dismissed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminNotes': '',
        'resolvedAt': null,
        'resolvedBy': null,
      };

      await _firestore.collection('system_reports').add(reportData);
      print('System issue reported successfully');
      return true;
    } catch (e) {
      print('Error reporting system issue: $e');
      return false;
    }
  }

  /// Stream system reports for admin dashboard
  Stream<List<Map<String, dynamic>>> streamSystemReports({String? status}) {
    Query query = _firestore
        .collection('system_reports')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Admin: Update system report status
  Future<bool> updateSystemReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      if (status == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
        updateData['resolvedBy'] = _auth.currentUser?.email ?? 'admin';
      }

      await _firestore
          .collection('system_reports')
          .doc(reportId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating system report status: $e');
      return false;
    }
  }
}
