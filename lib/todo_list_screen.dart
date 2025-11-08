import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import './task.dart';
import './task_detail_screen.dart';
import './database_helper.dart';
import './login_screen.dart';

class TodoListScreen extends StatefulWidget {
  final int userId;

  const TodoListScreen({super.key, required this.userId});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Task> _tasks = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_tasks.isNotEmpty && _listKey.currentState != null) {
      for (int i = _tasks.length - 1; i >= 0; i--) {
        final removed = _tasks.removeAt(i);
        _listKey.currentState!.removeItem(
          i,
              (context, animation) => _buildRemovedTaskItem(removed, animation),
          duration: const Duration(milliseconds: 150),
        );
      }
    } else {
      _tasks.clear();
    }

    final fetched = await DatabaseHelper.instance.getTasks(widget.userId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var i = 0; i < fetched.length; i++) {
        _tasks.add(fetched[i]);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 200));
      }
      setState(() {});
    });
  }

  Future<void> _addTask(String title, String? description, DateTime? deadline) async {
    if (title.trim().isEmpty) return;

    final task = Task(title: title.trim(), description: description?.trim(), deadline: deadline);
    final id = await DatabaseHelper.instance.addTask(task, widget.userId);
    final newTask = task.copyWith(id: id);

    final insertIndex = _tasks.length;
    _tasks.add(newTask);
    _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 250));

    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    setState(() {});
  }

  Future<void> _removeTask(int taskId, int index) async {
    final removedTask = _tasks.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildRemovedTaskItem(removedTask, animation),
      duration: const Duration(milliseconds: 300),
    );

    await DatabaseHelper.instance.deleteTask(taskId);
    setState(() {});
  }

  Widget _buildRemovedTaskItem(Task task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: ListTile(
          title: Text(task.title),
          subtitle: task.deadline != null
              ? Text(
            intl.DateFormat("'Deadline:' yyyy-MM-dd – h:mm a").format(task.deadline!),
          )
              : null,
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final newStatus =
    task.status == TaskStatus.completed ? TaskStatus.inProgress : TaskStatus.completed;
    final updatedTask = task.copyWith(status: newStatus);

    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      setState(() {});
    }

    await DatabaseHelper.instance.updateTask(updatedTask);
  }

  Future<void> _navigateToDetail(Task task) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (result != null) {
      final updatedTask = task.copyWith(
        title: (result['title'] as String?)?.trim().isNotEmpty == true
            ? result['title'] as String
            : task.title,
        description: result['description'] as String? ?? task.description,
        status: result['status'] as TaskStatus? ?? task.status,
      );

      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = updatedTask;
        setState(() {});
      }

      await DatabaseHelper.instance.updateTask(updatedTask);
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _selectDate(BuildContext context, StateSetter setInnerState) async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setInnerState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _displayDialog() async {
    _selectedDate = null;
    _titleController.clear();
    _descriptionController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              title: const Text('Add a new task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Enter task description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No deadline set'
                              : intl.DateFormat('yyyy-MM-dd – h:mm a').format(_selectedDate!),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, setInnerState),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    _addTask(_titleController.text, _descriptionController.text, _selectedDate);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _tasks.length, // la start e 0; items vin prin _loadTasks()
        itemBuilder: (context, index, animation) {
          final task = _tasks[index];
          return _buildTaskItem(task, animation, index, textTheme);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _displayDialog,
        tooltip: 'Add Task',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskItem(
      Task task,
      Animation<double> animation,
      int index,
      TextTheme textTheme,
      ) {
    final isDone = task.status == TaskStatus.completed;

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: ListTile(
          onTap: () => _navigateToDetail(task),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: isDone,
            onChanged: (_) => _toggleTaskCompletion(task),
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            task.title,
            style: textTheme.titleMedium?.copyWith(
              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
              color: isDone ? Colors.grey[600] : null,
              fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((task.description ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    task.description!.trim(),
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (task.deadline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    intl.DateFormat("'Deadline:' yyyy-MM-dd – h:mm a").format(task.deadline!),
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _removeTask(task.id!, index),
          ),
        ),
      ),
    );
  }
}
