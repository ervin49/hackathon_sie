enum TaskStatus { inProgress, completed }

class Task {
  Task({
    this.id,
    required this.title,
    this.description,
    this.deadline,
    TaskStatus? status,
  }) : status = status ?? TaskStatus.inProgress;

  final int? id;
  String title;
  String? description;
  TaskStatus status;
  DateTime? deadline;
}
