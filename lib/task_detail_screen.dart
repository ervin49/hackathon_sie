import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './task.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color _statusToColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  void _popWithResult() {
    Navigator.of(context).pop({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _popWithResult,
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          _popWithResult(); // Also handle system back gesture
          return true;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  const Text('Status:'),
                  const SizedBox(width: 8.0),
                  Text(
                    _statusToString(_status),
                    style: TextStyle(
                      color: _statusToColor(_status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.task.deadline != null) ...[
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Text('Deadline:'),
                    const SizedBox(width: 8.0),
                    Text(
                      DateFormat('yyyy-MM-dd – h:mm a').format(widget.task.deadline!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32.0),
              const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = TaskStatus.inProgress;
                      });
                    },
                    child: const Text('In Progress'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = TaskStatus.completed;
                      });
                    },
                    child: const Text('Completed'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
