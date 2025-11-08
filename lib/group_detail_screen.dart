import 'package:flutter/material.dart';
import './database_helper.dart';
import './group.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final int currentUserId;

  const GroupDetailScreen({super.key, required this.group, required this.currentUserId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadAllUsers();
  }

  Future<void> _loadMembers() async {
    final members = await DatabaseHelper.instance.getGroupMembers(widget.group.id);
    if (mounted) setState(() => _members = members);
  }

  Future<void> _loadAllUsers() async {
    final users = await DatabaseHelper.instance.getAllUsers();
    if (mounted) setState(() => _allUsers = users);
  }

  Future<void> _showSendInvitationDialog() async {
    int? selectedUserId;
    final availableUsers = _allUsers.where((user) {
      return !_members.any((member) => member['id'] == user['id']);
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Group Invitation'),
              content: DropdownButton<int>(
                hint: const Text('Select a user to invite'),
                value: selectedUserId,
                isExpanded: true,
                items: availableUsers.map((user) => DropdownMenuItem<int>(value: user['id'] as int, child: Text(user['username'] as String))).toList(),
                onChanged: (value) => setState(() => selectedUserId = value),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId != null) {
                      await DatabaseHelper.instance.sendGroupInvitation(widget.currentUserId, selectedUserId!, widget.group.id);
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
                      }
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(member['username'] as String),
            trailing: Text(member['role'] as String, style: TextStyle(color: Colors.grey[600])),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendInvitationDialog,
        tooltip: 'Invite Member',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
