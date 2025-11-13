import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug tool to check AR model data in Firestore
/// Use this to diagnose why models aren't appearing
class ARModelDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if AR models exist for a video
  static Future<void> debugVideoARModels(String videoId) async {
    print('\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('┃ AR MODEL DEBUGGER');
    print('┃ Video ID: $videoId');
    print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    try {
      // Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        print('   User NOT authenticated');
        print('   → AR models require authentication to view\n');
        return;
      }
      print('    User authenticated: ${user.uid}');
      print('   Email: ${user.email ?? "No email"}\n');

      // Check if video exists
      print('🔍 Checking if video exists...');
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();

      if (!videoDoc.exists) {
        print('     Video NOT FOUND in Firestore');
        print('   → Video ID might be incorrect\n');
        return;
      }
      print('✅ Video exists');
      final videoData = videoDoc.data()!;
      print('   Title: ${videoData['title'] ?? "No title"}');
      print('   Uploader: ${videoData['userId'] ?? "Unknown"}\n');

      // Check AR models collection
      print('🔍 Checking AR models collection...');
      print('   Path: videos/$videoId/arModels\n');

      final arModelsSnapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .get();

      if (arModelsSnapshot.docs.isEmpty) {
        print('❌ NO AR MODELS FOUND');
        print('   → This video has no AR models uploaded yet');
        print(
            '   → Upload models via "Manage AR Models" if you\'re the uploader\n');
        return;
      }

      print('📦 Found ${arModelsSnapshot.docs.length} AR model documents:\n');

      for (var doc in arModelsSnapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? false;

        print('┌─ Model ID: ${doc.id}');
        print('│  Name: ${data['modelName'] ?? "Unnamed"}');
        print('│  Active: ${isActive ? "✅ YES" : "❌ NO"}');
        print('│  Image URL: ${data['imageUrl'] ?? "None"}');
        print('│  Uploader: ${data['uploaderId'] ?? "Unknown"}');
        print('│  Created: ${data['createdAt'] ?? "Unknown"}');
        print('└─────────────────────────────────────────\n');

        if (!isActive) {
          print(
              '   ⚠️ This model is INACTIVE and won\'t appear in AR Scanner\n');
        }
      }

      // Check active models
      final activeModels = arModelsSnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .toList();

      if (activeModels.isEmpty) {
        print('❌ NO ACTIVE AR MODELS');
        print('   → All models are marked as inactive');
        print('   → They won\'t appear in the AR Scanner\n');
      } else {
        print('✅ ${activeModels.length} ACTIVE AR MODELS');
        print('   → These should appear in AR Scanner\n');
      }

      // Test the query that the app uses
      print('🔍 Testing the actual app query...');
      print(
          '   Query: where("isActive", ==, true).orderBy("createdAt", desc)\n');

      try {
        final testSnapshot = await _firestore
            .collection('videos')
            .doc(videoId)
            .collection('arModels')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        print('✅ Query executed successfully');
        print('   Results: ${testSnapshot.docs.length} documents\n');

        if (testSnapshot.docs.isEmpty) {
          print('❌ Query returned NO documents');
          print('   Possible causes:');
          print('   1. No active models exist');
          print('   2. Firestore index missing');
          print('   3. Security rules blocking access\n');
        }
      } catch (e) {
        print('❌ Query FAILED');
        print('   Error: $e');
        print('   → This is why models aren\'t loading!\n');

        if (e.toString().contains('index')) {
          print('🔧 FIX: Create Firestore index');
          print('   1. Go to Firebase Console → Firestore → Indexes');
          print('   2. Create composite index:');
          print('      Collection: arModels (subcollection of videos)');
          print('      Fields: isActive (ASC), createdAt (DESC)\n');
        }

        if (e.toString().contains('permission') ||
            e.toString().contains('PERMISSION_DENIED')) {
          print('🔧 FIX: Update Firestore Security Rules');
          print('   Add this rule:');
          print('   match /videos/{videoId}/arModels/{modelId} {');
          print('     allow read: if resource.data.isActive == true;');
          print('   }\n');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    } catch (e, stackTrace) {
      print('❌ DEBUG ERROR: $e');
      print('Stack trace: $stackTrace\n');
    }
  }

  /// Quick check for multiple videos
  static Future<void> quickCheck(List<String> videoIds) async {
    print('\n📊 QUICK CHECK FOR ${videoIds.length} VIDEOS\n');

    for (var videoId in videoIds) {
      try {
        final snapshot = await _firestore
            .collection('videos')
            .doc(videoId)
            .collection('arModels')
            .where('isActive', isEqualTo: true)
            .get();

        if (snapshot.docs.isEmpty) {
          print('❌ $videoId: No active models');
        } else {
          print('✅ $videoId: ${snapshot.docs.length} active models');
        }
      } catch (e) {
        print('⚠️ $videoId: Error - $e');
      }
    }
    print('');
  }

  /// List ALL videos with AR models
  static Future<void> listAllVideosWithARModels() async {
    print('\n🔍 SEARCHING FOR ALL VIDEOS WITH AR MODELS...\n');

    try {
      final videosSnapshot = await _firestore.collection('videos').get();
      print('Found ${videosSnapshot.docs.length} total videos\n');

      int videosWithModels = 0;
      int totalModels = 0;

      for (var videoDoc in videosSnapshot.docs) {
        final arModelsSnapshot = await _firestore
            .collection('videos')
            .doc(videoDoc.id)
            .collection('arModels')
            .where('isActive', isEqualTo: true)
            .get();

        if (arModelsSnapshot.docs.isNotEmpty) {
          videosWithModels++;
          totalModels += arModelsSnapshot.docs.length;

          final videoData = videoDoc.data();
          print('✅ ${videoDoc.id}');
          print('   Title: ${videoData['title'] ?? "Untitled"}');
          print('   AR Models: ${arModelsSnapshot.docs.length}');
          print('');
        }
      }

      if (videosWithModels == 0) {
        print('❌ NO VIDEOS HAVE AR MODELS');
        print('   → Upload some AR models to test\n');
      } else {
        print('📊 SUMMARY:');
        print('   Videos with AR models: $videosWithModels');
        print('   Total AR models: $totalModels\n');
      }
    } catch (e) {
      print('❌ Error: $e\n');
    }
  }
}
