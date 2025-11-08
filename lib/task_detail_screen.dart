import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import './task.dart';
import './database_helper.dart';
import './history.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final int currentUserId;

  const TaskDetailScreen({super.key, required this.task, required this.currentUserId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskStatus _status;

  List<String> _participants = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<History> _history = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
    _loadParticipants();
    _loadAllUsers();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    final participants = await DatabaseHelper.instance.getTaskParticipants(widget.task.id!);
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _loadAllUsers() async {
    final users = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      _allUsers = users;
    });
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseHelper.instance.getTaskHistory(widget.task.id!);
    setState(() {
      _history = history;
    });
  }

  String _statusToString(TaskStatus status) {
    return status == TaskStatus.inProgress ? 'In Progress' : 'Completed';
  }

  Color _statusToColor(TaskStatus status) {
    return status == TaskStatus.inProgress ? Colors.blue : Colors.green;
  }

  Future<void> _saveAndPop() async {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      status: _status,
    );
    await DatabaseHelper.instance.updateTask(updatedTask, widget.currentUserId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showSendInvitationDialog() async {
    int? selectedUserId;
    final availableUsers = _allUsers.where((user) {
      return !_participants.contains(user['username'] as String) && user['id'] != widget.currentUserId;
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Invitation'),
              content: DropdownButton<int>(
                hint: const Text('Select a user to invite'),
                value: selectedUserId,
                isExpanded: true,
                items: availableUsers.map((user) {
                  return DropdownMenuItem<int>(
                    value: user['id'] as int,
                    child: Text(user['username'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUserId = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedUserId != null) {
                      await DatabaseHelper.instance.sendInvitation(widget.currentUserId, selectedUserId!, widget.task.id!);
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent!')),
                        );
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
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveAndPop,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          await _saveAndPop();
          return true;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  const Text('Status:'),
                  const SizedBox(width: 8.0),
                  Text(_statusToString(_status), style: TextStyle(color: _statusToColor(_status), fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.task.deadline != null) ...[
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Text('Deadline:'),
                    const SizedBox(width: 8.0),
                    Text(intl.DateFormat('yyyy-MM-dd – h:mm a').format(widget.task.deadline!), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 24.0),
              const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () => setState(() => _status = TaskStatus.inProgress), child: const Text('In Progress')),
                  ElevatedButton(onPressed: () => setState(() => _status = TaskStatus.completed), child: const Text('Completed')),
                ],
              ),
              const SizedBox(height: 24.0),
              const Divider(),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(onPressed: _showSendInvitationDialog, icon: const Icon(Icons.person_add_alt_1_outlined), tooltip: 'Invite User'),
                ],
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _participants.map((name) => Chip(label: Text(name))).toList(),
              ),
              const SizedBox(height: 24.0),
              const Divider(),
              const SizedBox(height: 16.0),
              const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8.0),
              _history.isEmpty
                  ? const Text('No history for this task yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final event = _history[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(event.action),
                          subtitle: Text('by ${event.username} at ${intl.DateFormat('yyyy-MM-dd – h:mm a').format(DateTime.parse(event.timestamp))}'),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
