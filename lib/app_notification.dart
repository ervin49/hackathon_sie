enum NotificationType { task, group }

class AppNotification {
  final int id;
  final String fromUser;
  final String itemName; // Task title or Group name
  final int itemId;     // Task ID or Group ID
  final int fromUserId;
  final NotificationType type;
  final String status;

  AppNotification({
    required this.id,
    required this.fromUser,
    required this.itemName,
    required this.itemId,
    required this.fromUserId,
    required this.type,
    required this.status,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int,
      fromUser: map['fromUser'] as String,
      itemName: map['itemName'] as String,
      itemId: map['itemId'] as int,
      fromUserId: map['fromUserId'] as int,
      type: (map['type'] as String) == 'task' ? NotificationType.task : NotificationType.group,
      status: map['status'] as String,
    );
  }
}
