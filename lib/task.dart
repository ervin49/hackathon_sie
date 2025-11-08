enum TaskStatus { inProgress, completed }

class Task {
  Task({
    this.id,
    required this.title,
    this.description,
    this.deadline,
    this.participantCount = 1,
    TaskStatus? status,
  }) : status = status ?? TaskStatus.inProgress;

  final int? id;
  String title;
  String? description;
  TaskStatus status;
  DateTime? deadline;
  final int participantCount;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskStatus? status,
    int? participantCount,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      participantCount: participantCount ?? this.participantCount,
    );
  }
}
