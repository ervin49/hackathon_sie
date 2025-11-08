class Subtask {
  final int id;
  final String title;
  bool isDone;

  Subtask({required this.id, required this.title, this.isDone = false});

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as int,
      title: map['title'] as String,
      isDone: map['isDone'] == 1,
    );
  }
}
