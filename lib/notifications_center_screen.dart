import 'package:flutter/material.dart';
import './database_helper.dart';
import './app_notification.dart';

class NotificationsCenterScreen extends StatefulWidget {
  final int userId;

  const NotificationsCenterScreen({super.key, required this.userId});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  List<AppNotification> _notifications = [];

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

  Future<void> _accept(AppNotification notification) async {
    await DatabaseHelper.instance.acceptInvitation(notification, widget.userId);
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted!')),
      );
    }
  }

  Future<void> _decline(AppNotification notification) async {
    await DatabaseHelper.instance.declineInvitation(notification);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Invitations')),
      body: _notifications.isEmpty
          ? const Center(child: Text('No new invitations.'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isTask = notification.type == NotificationType.task;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: Icon(isTask ? Icons.task_alt : Icons.group_add_outlined),
                    title: Text('\'${notification.fromUser}\' invited you to join:'),
                    subtitle: Text(notification.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _accept(notification),
                          child: const Text('Accept'),
                          style: TextButton.styleFrom(foregroundColor: Colors.green),
                        ),
                        TextButton(
                          onPressed: () => _decline(notification),
                          child: const Text('Decline'),
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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
