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
  List<Task> _tasks = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance.getTasks(widget.userId);
    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _addTask(String title, String? description, DateTime? deadline) async {
    if (title.isNotEmpty) {
      final task = Task(title: title, description: description, deadline: deadline);
      await DatabaseHelper.instance.addTask(task, widget.userId);
      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
      _loadTasks();
    }
  }

  Future<void> _removeTask(int taskId) async {
    await DatabaseHelper.instance.deleteTask(taskId);
    _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (task.status == TaskStatus.completed) {
      task.status = TaskStatus.inProgress;
    } else {
      task.status = TaskStatus.completed;
    }
    await DatabaseHelper.instance.updateTask(task);
    _loadTasks();
  }

  void _navigateToDetail(Task task) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (result != null) {
      task.status = result['status'];
      task.description = result['description'];
      await DatabaseHelper.instance.updateTask(task);
      _loadTasks();
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _selectDate(BuildContext context, StateSetter setState) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
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
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
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
                              : intl.DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDate!),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context, setState),
                      )
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'To-Do List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_box_outline_blank, size: 80, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet. Add one!',
                    style: TextStyle(fontSize: 18.0, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  child: ListTile(
                    onTap: () {
                      _navigateToDetail(task);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: (bool? value) {
                        _toggleTaskCompletion(task);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.status == TaskStatus.completed ? Colors.grey[500] : Colors.white,
                        fontWeight: task.status == TaskStatus.completed ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null && task.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              task.description!,
                              style: TextStyle(color: Colors.grey[400]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (task.deadline != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              intl.DateFormat('Deadline: yyyy-MM-dd – kk:mm').format(task.deadline!),
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _removeTask(task.id!),
                    ),
                  ),
                );
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
}
