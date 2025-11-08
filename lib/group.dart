class Group {
  final int id;
  final String name;
  final int ownerId;
  final int memberCount;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    this.memberCount = 1,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as int,
      name: map['name'] as String,
      ownerId: map['ownerId'] as int,
      memberCount: map['memberCount'] as int? ?? 1,
    );
  }
}
