import 'package:flutter/material.dart';
import 'package:rexplore/services/notification_service.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final Set<String> _expandedNotifications = {};

  void _toggleExpansion(String notifId) {
    setState(() {
      if (_expandedNotifications.contains(notifId)) {
        _expandedNotifications.remove(notifId);
      } else {
        _expandedNotifications.add(notifId);
      }
    });
  }

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
      case 'warning':
        return Icons.warning;
      case 'suspension':
        return Icons.block;
      case 'unsuspension':
        return Icons.check_circle;
      case 'account_deletion':
        return Icons.delete_forever;
      case 'account_restoration':
        return Icons.restore;
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
                  thumbnailUrl: data['thumbnailUrl'] ?? '',
                ),
              ),
            );
          }
        });
      }
    }
  }

  Widget _buildExpandableMessage(BuildContext context,
      Map<String, dynamic> notif, ThemeData theme, bool isRead) {
    final message = notif['message'] ?? '';
    final notifId = notif['id'];
    final isExpanded = _expandedNotifications.contains(notifId);

    // Estimate if text needs expansion (rough estimate: ~80 chars = 2 lines)
    final needsExpansion = message.length > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium,
          maxLines: isExpanded ? null : 2,
          overflow: isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (needsExpansion)
          GestureDetector(
            onTap: () => _toggleExpansion(notifId),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Show less' : 'Show more',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
                child: InkWell(
                  onTap: () {
                    if (!isRead) {
                      notificationService.markAsRead(notif['id']);
                    }
                    _handleNotificationTap(context, notif);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? null
                          : theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif['title'] ?? 'Notification',
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTimestamp(notif['createdAt']),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              _buildExpandableMessage(
                                  context, notif, theme, isRead),
                            ],
                          ),
                        ),
                      ],
                    ),
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
