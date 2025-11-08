class History {
  final String action;
  final String username;
  final String timestamp;

  History({
    required this.action,
    required this.username,
    required this.timestamp,
  });

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      action: map['action'] as String,
      username: map['username'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}
