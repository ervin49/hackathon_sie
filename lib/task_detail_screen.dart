import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './task.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 8.0),
                Text(
                  task.completed ? 'Completed' : 'Incomplete',
                  style: TextStyle(
                    color: task.completed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (task.deadline != null) ...[
              const SizedBox(height: 16.0),
              Row(
                children: [
                  const Text('Deadline:'),
                  const SizedBox(width: 8.0),
                  Text(
                    DateFormat('yyyy-MM-dd – kk:mm').format(task.deadline!),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
