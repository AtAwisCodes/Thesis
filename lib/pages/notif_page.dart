import 'package:flutter/material.dart';
import 'package:rexplore/services/notification_service.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotifPage extends StatelessWidget {
  const NotifPage({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'newVideo':
        return Icons.videocam;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Just now';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _handleNotificationTap(
      BuildContext context, Map<String, dynamic> notif) {
    final type = notif['type'];

    if (type == 'like' || type == 'newVideo') {
      // Navigate to video player
      final videoId = notif['videoId'];
      if (videoId != null && videoId.isNotEmpty) {
        // Fetch video details and navigate
        FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .get()
            .then((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadedVideoPlayer(
                  videoUrl: data['publicUrl'] ?? '',
                  title: data['title'] ?? 'Untitled',
                  uploadedAt: data['uploadedAt'] != null
                      ? DateFormat('MMM d, yyyy')
                          .format((data['uploadedAt'] as Timestamp).toDate())
                      : 'Unknown',
                  avatarUrl: data['avatarUrl'] ?? '',
                  firstName: data['firstName'] ?? '',
                  lastName: data['lastName'] ?? '',
                  videoId: videoId,
                ),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.dividerColor.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] ?? false;

              return Dismissible(
                key: Key(notif['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  notificationService.deleteNotification(notif['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: ListTile(
                  onTap: () {
                    if (!isRead) {
                      notificationService.markAsRead(notif['id']);
                    }
                    _handleNotificationTap(context, notif);
                  },
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: notif['fromUserAvatar'] != null &&
                            notif['fromUserAvatar'].isNotEmpty
                        ? NetworkImage(notif['fromUserAvatar'])
                        : null,
                    child: notif['fromUserAvatar'] == null ||
                            notif['fromUserAvatar'].isEmpty
                        ? Icon(
                            _getIconForType(notif['type']),
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                  title: Text(
                    notif['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    notif['message'] ?? '',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTimestamp(notif['createdAt']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  tileColor: isRead
                      ? null
                      : theme.colorScheme.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
