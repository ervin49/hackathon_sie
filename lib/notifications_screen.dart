import 'package:flutter/material.dart';
import './database_helper.dart';
import './notification.dart' as app_notification;

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<app_notification.Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await DatabaseHelper.instance.getNotifications(widget.userId);
    if (mounted) {
      setState(() {
        _notifications = notifications.where((n) => n.status == 'pending').toList();
      });
    }
  }

  Future<void> _accept(app_notification.Notification notification) async {
    await DatabaseHelper.instance.acceptInvitation(notification.id, widget.userId, notification.taskId);
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted!')),
      );
    }
  }

  Future<void> _decline(app_notification.Notification notification) async {
    await DatabaseHelper.instance.declineInvitation(notification.id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text('No new notifications.'),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text('\'${notification.fromUser}\' invited you to join:'),
                    subtitle: Text(notification.taskTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _accept(notification),
                          child: const Text('Accept'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _decline(notification),
                          child: const Text('Decline'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
