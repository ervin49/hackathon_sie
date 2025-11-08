import 'package:flutter/material.dart';
import './database_helper.dart';
import './group.dart';
import './group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  final int userId;

  const GroupsScreen({super.key, required this.userId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  final _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await DatabaseHelper.instance.getGroupsForUser(widget.userId);
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text;
    if (groupName.isNotEmpty) {
      await DatabaseHelper.instance.createGroup(groupName, widget.userId);
      _loadGroups();
      _groupNameController.clear();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _navigateToGroupDetail(Group group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(group: group, currentUserId: widget.userId),
      ),
    );
    _loadGroups();
  }

  Future<void> _displayCreateGroupDialog() async {
    _groupNameController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a New Group'),
          content: TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(hintText: 'Enter group name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: _createGroup, child: const Text('Create')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Groups')),
      body: _groups.isEmpty
          ? const Center(child: Text('No groups yet. Create one!'))
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: const Icon(Icons.group, size: 40),
                    onTap: () => _navigateToGroupDetail(group),
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${group.memberCount} member(s)'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _displayCreateGroupDialog,
        tooltip: 'Create Group',
        child: const Icon(Icons.add),
      ),
    );
  }
}
