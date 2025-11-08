class Task {
  Task({required this.title, this.completed = false, this.deadline});
  String title;
  bool completed;
  DateTime? deadline;
}
