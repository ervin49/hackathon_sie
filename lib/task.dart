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

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskStatus? status,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }
}
