import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import './task.dart';
import './task_detail_screen.dart';
import './database_helper.dart';
import './login_screen.dart';
import './notifications_center_screen.dart';
import './groups_screen.dart';
import './notification_service.dart';
import './profile_screen.dart';

class TodoListScreen extends StatefulWidget {
  final int userId;

  const TodoListScreen({super.key, required this.userId});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Task> _tasks = [];
  int _notificationCount = 0;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTasks();
    await _loadNotificationCount();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper.instance.getTasks(widget.userId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    final notifications = await DatabaseHelper.instance.getNotifications(widget.userId);
    if (mounted) {
      setState(() {
        _notificationCount = notifications.where((n) => n.status == 'pending').length;
      });
    }
  }

  Future<void> _addTask(String title, String? description, DateTime? deadline) async {
    final task = Task(title: title, description: description, deadline: deadline);
    final taskId = await DatabaseHelper.instance.addTask(task, widget.userId);
    if (deadline != null) {
      _notificationService.scheduleDeadlineNotification(taskId, title, deadline);
    }
    _loadTasks();
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
  }

  Future<void> _removeTask(int taskId) async {
    await DatabaseHelper.instance.deleteTask(taskId, widget.userId);
    _notificationService.cancelNotification(taskId);
    _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      status: task.status == TaskStatus.completed
          ? TaskStatus.inProgress
          : TaskStatus.completed,
    );
    await DatabaseHelper.instance.updateTask(updatedTask, widget.userId);
    _loadTasks();
  }

  void _navigateToDetail(Task task) async {
    final originalDeadline = task.deadline;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task, currentUserId: widget.userId),
      ),
    );
    _loadData(); // Reload all data
    final updatedTask = _tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
    if (updatedTask.deadline != originalDeadline) {
      if (originalDeadline != null) {
        _notificationService.cancelNotification(task.id!);
      }
      if (updatedTask.deadline != null) {
        _notificationService.scheduleDeadlineNotification(updatedTask.id!, updatedTask.title, updatedTask.deadline!);
      }
    }
  }

  void _navigateToNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationsCenterScreen(userId: widget.userId),
      ),
    );
    _loadData(); // Reload all data
  }

  void _navigateToGroups() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupsScreen(userId: widget.userId),
      ),
    );
    _loadData(); // Reload all data
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.userId),
      ),
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
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              title: const Text('Add a new task'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Enter task title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.length < 3) {
                          return 'Title must be at least 3 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(hintText: 'Enter task description'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text(_selectedDate == null ? 'No deadline set' : intl.DateFormat('yyyy-MM-dd – kk:mm').format(_selectedDate!))),
                        IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context, setState)),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _addTask(_titleController.text, _descriptionController.text, _selectedDate);
                      Navigator.of(context).pop();
                    }
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
        title: const Text('Your Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.group_outlined), onPressed: _navigateToGroups, tooltip: 'Groups'),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _navigateToNotifications, tooltip: 'Notifications'),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: _navigateToProfile, tooltip: 'Profile'),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_add_check_outlined, size: 100, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('No tasks yet.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Tap the + button to add your first task.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  child: ListTile(
                    onTap: () => _navigateToDetail(task),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Checkbox(
                      value: task.status == TaskStatus.completed,
                      onChanged: (bool? value) => _toggleTaskCompletion(task),
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : TextDecoration.none,
                              color: task.status == TaskStatus.completed ? Colors.grey : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          avatar: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onSecondaryContainer),
                          label: Text('${task.participantCount}'),
                        ),
                      ],
                    ),
                    subtitle: task.description != null && task.description!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])),
                          )
                        : null,
                    isThreeLine: task.description != null && task.description!.isNotEmpty,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _removeTask(task.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _displayDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
