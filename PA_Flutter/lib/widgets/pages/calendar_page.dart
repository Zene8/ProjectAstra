import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:projectastra/services/task_service.dart'; // New TaskService
import 'package:projectastra/models/task_models.dart'; // New Task models
import 'package:provider/provider.dart'; // Import Provider
import 'package:projectastra/services/auth_service.dart'; // Import AuthService

enum TaskProvider {
  googleTasks,
  microsoftToDo,
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  TaskProvider _selectedTaskProvider = TaskProvider.googleTasks; // Default to Google Tasks
  late TaskService _taskService; // Declare TaskService

  final List<Task> _tasks = [];
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskService = TaskService(Provider.of<AuthService>(context, listen: false));
      _fetchTasks(); // Fetch tasks on init
    });
  }

  Future<void> _fetchTasks() async {
    try {
      final fetchedTasks = await _taskService.fetchTasks(_selectedTaskProvider.toString().split('.').last);
      setState(() {
        _tasks.clear();
        _tasks.addAll(fetchedTasks);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  void _addTask() async {
    if (_taskController.text.isNotEmpty) {
      try {
        final newTask = await _taskService.createTask(
          _selectedTaskProvider.toString().split('.').last,
          _taskController.text,
        );
        setState(() {
          _tasks.add(newTask);
          _taskController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  void _updateTaskStatus(Task task, bool isDone) async {
    try {
      await _taskService.updateTask(
        _selectedTaskProvider.toString().split('.').last,
        'default', // TODO: Pass actual listId if needed
        task.id,
        isCompleted: isDone,
      );
      setState(() {
        task.isDone = isDone;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status: $e')),
      );
    }
  }

  void _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(
        _selectedTaskProvider.toString().split('.').last,
        'default', // TODO: Pass actual listId if needed
        task.id,
      );
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Tasks'),
        actions: [
          DropdownButton<TaskProvider>(
            value: _selectedTaskProvider,
            onChanged: (TaskProvider? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedTaskProvider = newValue;
                });
                _fetchTasks(); // Fetch tasks for the new provider
              }
            },
            items: const <DropdownMenuItem<TaskProvider>>[
              DropdownMenuItem<TaskProvider>(
                value: TaskProvider.googleTasks,
                child: Text('Google Tasks'),
              ),
              DropdownMenuItem<TaskProvider>(
                value: TaskProvider.microsoftToDo,
                child: Text('Microsoft To Do'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (value) {
                      _updateTaskStatus(task, value!); // Use new update function
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task), // Add delete button
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(labelText: 'New Task'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}