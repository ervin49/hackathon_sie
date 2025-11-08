class Notification {
  final int id;
  final String fromUser;
  final String taskTitle;
  final int taskId;
  final String status;

  Notification({
    required this.id,
    required this.fromUser,
    required this.taskTitle,
    required this.taskId,
    required this.status,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] as int,
      fromUser: map['fromUser'] as String,
      taskTitle: map['taskTitle'] as String,
      taskId: map['taskId'] as int,
      status: map['status'] as String,
    );
  }
}
