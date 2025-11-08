import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import './task.dart';
import './database_helper.dart';
import './history.dart';
import './group.dart';

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
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
    _loadParticipants();
    _loadAllUsers();
    _loadHistory();
    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    final participants = await DatabaseHelper.instance.getTaskParticipants(widget.task.id!);
    if (mounted) setState(() => _participants = participants);
  }

  Future<void> _loadAllUsers() async {
    final users = await DatabaseHelper.instance.getAllUsers();
    if (mounted) setState(() => _allUsers = users);
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseHelper.instance.getTaskHistory(widget.task.id!);
    if (mounted) setState(() => _history = history);
  }

  Future<void> _loadGroups() async {
    final groups = await DatabaseHelper.instance.getGroupsForUser(widget.currentUserId);
    if (mounted) setState(() => _groups = groups);
  }

  String _statusToString(TaskStatus status) => status == TaskStatus.inProgress ? 'In Progress' : 'Completed';

  Color _statusToColor(TaskStatus status) => status == TaskStatus.inProgress ? Colors.blueAccent : Colors.green;

  Future<void> _saveChanges() async {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      status: _status,
    );
    await DatabaseHelper.instance.updateTask(updatedTask, widget.currentUserId);
    _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes applied!')),
      );
    }
  }

  Future<void> _showSendInvitationDialog() async {
    int? selectedUserId;
    int? selectedGroupId;
    final availableUsers = _allUsers.where((user) => !_participants.contains(user['username'] as String) && user['id'] != widget.currentUserId).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Invitation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    hint: const Text('Select a user to invite'),
                    value: selectedUserId,
                    isExpanded: true,
                    items: availableUsers.map((user) => DropdownMenuItem<int>(value: user['id'] as int, child: Text(user['username'] as String))).toList(),
                    onChanged: (value) => setState(() => selectedUserId = value),
                  ),
                  const SizedBox(height: 20),
                  const Text('Or invite a group:'),
                  DropdownButton<int>(
                    hint: const Text('Select a group to invite'),
                    value: selectedGroupId,
                    isExpanded: true,
                    items: _groups.map((group) => DropdownMenuItem<int>(value: group.id, child: Text(group.name))).toList(),
                    onChanged: (value) => setState(() => selectedGroupId = value),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId != null) {
                      await DatabaseHelper.instance.sendTaskInvitation(widget.currentUserId, selectedUserId!, widget.task.id!);
                    } else if (selectedGroupId != null) {
                      final members = await DatabaseHelper.instance.getGroupMembers(selectedGroupId!);
                      for (var member in members) {
                        if (member['id'] != widget.currentUserId) {
                          await DatabaseHelper.instance.sendTaskInvitation(widget.currentUserId, member['id'] as int, widget.task.id!);
                        }
                      }
                    }
                    _loadHistory();
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation(s) sent!')));
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _titleController, style: theme.textTheme.headlineSmall, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 20.0),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: null, keyboardType: TextInputType.multiline),
            const SizedBox(height: 24.0),
            _buildSectionHeader(context, 'Status'),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 12.0),
                Text(_statusToString(_status), style: theme.textTheme.bodyLarge?.copyWith(color: _statusToColor(_status), fontWeight: FontWeight.bold)),
              ],
            ),
            if (widget.task.deadline != null) ...[
              const SizedBox(height: 16.0),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 12.0),
                  Text(intl.DateFormat('MMM d, yyyy – h:mm a').format(widget.task.deadline!), style: theme.textTheme.bodyLarge),
                ],
              ),
            ],
            const SizedBox(height: 24.0),
            _buildSectionHeader(context, 'Change Status'),
            const SizedBox(height: 12.0),
            SegmentedButton<TaskStatus>(
              segments: const [
                ButtonSegment(value: TaskStatus.inProgress, label: Text('In Progress'), icon: Icon(Icons.work_history_outlined)),
                ButtonSegment(value: TaskStatus.completed, label: Text('Completed'), icon: Icon(Icons.check_circle_outline)),
              ],
              selected: {_status},
              onSelectionChanged: (newSelection) => setState(() => _status = newSelection.first),
            ),
            const SizedBox(height: 24.0),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveChanges, child: const Text('Apply Changes'))),
            const SizedBox(height: 24.0),
            _buildSectionHeader(context, 'Participants', action: IconButton(onPressed: _showSendInvitationDialog, icon: const Icon(Icons.person_add_alt_1), tooltip: 'Invite User')),
            const SizedBox(height: 8.0),
            _participants.isEmpty
                ? const Text('Just you for now.')
                : Wrap(spacing: 8.0, runSpacing: 8.0, children: _participants.map((name) => Chip(avatar: const Icon(Icons.person), label: Text(name))).toList()),
            const SizedBox(height: 24.0),
            _buildSectionHeader(context, 'History'),
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
                        subtitle: Text('by ${event.username} at ${intl.DateFormat('MMM d, h:mm a').format(DateTime.parse(event.timestamp))}'),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null) action,
      ],
    );
  }
}
