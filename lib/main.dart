import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import './task.dart';
import './task_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF311B92),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _textFieldController = TextEditingController();
  DateTime? _selectedDate;

  void _addTask(String title, DateTime? deadline) {
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: title, deadline: deadline));
      });
      _textFieldController.clear();
      _selectedDate = null;
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
    });
  }

  void _navigateToDetail(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
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
                    controller: _textFieldController,
                    decoration: const InputDecoration(
                      hintText: 'Enter task here',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
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
                    _textFieldController.clear();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    _addTask(_textFieldController.text, _selectedDate);
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
                      if (!task.completed) {
                        _navigateToDetail(task);
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (bool? value) {
                        _toggleTaskCompletion(index);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.completed ? Colors.grey[500] : Colors.white,
                        fontWeight: task.completed ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    subtitle: task.deadline != null
                        ? Text(
                            intl.DateFormat('Deadline: yyyy-MM-dd – kk:mm').format(task.deadline!),
                            style: TextStyle(color: Colors.grey[400]),
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _removeTask(index),
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
