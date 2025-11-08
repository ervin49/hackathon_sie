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

class _TodoListScreenState extends State<TodoListScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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
    for (var i = 0; i < tasks.length; i++) {
      _tasks.add(tasks[i]);
      _listKey.currentState?.insertItem(i);
    }
  }

  Future<void> _addTask(String title, String? description, DateTime? deadline) async {
    if (title.isNotEmpty) {
      final task = Task(title: title, description: description, deadline: deadline);
      final id = await DatabaseHelper.instance.addTask(task, widget.userId);
      final newTask = task.copyWith(id: id);

      _tasks.add(newTask);
      _listKey.currentState?.insertItem(_tasks.length - 1);

      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
    }
  }

  Future<void> _removeTask(int taskId, int index) async {
    final taskToRemove = _tasks[index];
    _tasks.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedTaskItem(taskToRemove, animation),
      duration: const Duration(milliseconds: 500),
    );
    await DatabaseHelper.instance.deleteTask(taskId);
  }

  Widget _buildRemovedTaskItem(Task task, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: ListTile(title: Text(task.title)),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (task.status == TaskStatus.completed) {
      task.status = TaskStatus.inProgress;
    } else {
      task.status = TaskStatus.completed;
    }
    await DatabaseHelper.instance.updateTask(task);
    setState(() {});
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
      setState(() {});
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
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _tasks.length,
        itemBuilder: (context, index, animation) {
          final task = _tasks[index];
          return _buildTaskItem(task, animation, index);
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

  Widget _buildTaskItem(Task task, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
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
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _removeTask(task.id!, index),
          ),
        ),
      ),
    );
  }
}
