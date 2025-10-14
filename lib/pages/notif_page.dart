import 'package:flutter/material.dart';

class NotifPage extends StatelessWidget {
  const NotifPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample notification data
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "New Like",
        "message": "Alex liked your post",
        "time": "2m ago",
        "icon": Icons.favorite,
        "isRead": false,
      },
      {
        "title": "New Follower",
        "message": "Maria started following you",
        "time": "10m ago",
        "icon": Icons.person_add,
        "isRead": false,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            Divider(color: theme.dividerColor.withOpacity(0.3)),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Dismissible(
            key: Key(index.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  notif["icon"],
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                notif["title"],
                style: TextStyle(
                  fontWeight:
                      notif["isRead"] ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                notif["message"],
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Text(
                notif["time"],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              tileColor: notif["isRead"]
                  ? null
                  : theme.colorScheme.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}
