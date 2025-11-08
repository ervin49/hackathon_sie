class GroupInvitation {
  final int id;
  final String fromUser;
  final String groupName;
  final int groupId;
  final String status;

  GroupInvitation({
    required this.id,
    required this.fromUser,
    required this.groupName,
    required this.groupId,
    required this.status,
  });

  factory GroupInvitation.fromMap(Map<String, dynamic> map) {
    return GroupInvitation(
      id: map['id'] as int,
      fromUser: map['fromUser'] as String,
      groupName: map['groupName'] as String,
      groupId: map['groupId'] as int,
      status: map['status'] as String,
    );
  }
}
