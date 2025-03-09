import 'package:example/screens/task_detail_screen.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../config/app_config.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Sample task data - in a real app, this would come from a service or database
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Complete project proposal',
      description: 'Finish the proposal for the new client project',
      dueDate: DateTime.now().add(Duration(days: 2)),
      priority: TaskPriority.high,
    ),
    Task(
      id: '2',
      title: 'Review pull requests',
      description: 'Review team pull requests for the API integration',
      dueDate: DateTime.now().add(Duration(days: 1)),
      priority: TaskPriority.medium,
    ),
    Task(
      id: '3',
      title: 'Update documentation',
      description: 'Update the user guide with the latest features',
      dueDate: DateTime.now().add(Duration(days: 5)),
      priority: TaskPriority.low,
    ),
    Task(
      id: '4',
      title: 'Prepare for meeting',
      description: 'Gather materials for the weekly team meeting',
      dueDate: DateTime.now(),
      priority: TaskPriority.high,
      isCompleted: true,
    ),
  ];

  void _toggleTaskStatus(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex != -1) {
        _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      }
    });
  }

  void _addNewTask() {
    // This would navigate to a task creation screen in a real app
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Task',
      description: 'Task description',
      dueDate: DateTime.now().add(Duration(days: 1)),
      priority: TaskPriority.medium,
    );

    setState(() {
      _tasks.add(newTask);
    });

    // Navigate to edit the new task
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: newTask),
      ),
    ).then((updatedTask) {
      if (updatedTask != null) {
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
          if (index != -1) {
            _tasks[index] = updatedTask;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = _tasks.where((task) => !task.isCompleted).toList();
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        actions: [
          // Only show sync button if sync feature is enabled
          if (AppConfig.enableSync)
            IconButton(
              icon: Icon(Icons.sync),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Syncing tasks...')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Show environment banner in non-production builds
          AppInfoBanner(),

          Expanded(
            child: ListView(
              children: [
                // Pending tasks section
                _buildTaskSection(
                  'Pending Tasks',
                  pendingTasks,
                  Icons.access_time,
                ),

                // Completed tasks section
                _buildTaskSection(
                  'Completed Tasks',
                  completedTasks,
                  Icons.check_circle,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon),
              SizedBox(width: 8),
              Text(
                '$title (${tasks.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('No tasks', style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskItem(task);
            },
          ),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    final isPastDue = !task.isCompleted &&
        task.dueDate.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => _toggleTaskStatus(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: isPastDue ? FontWeight.bold : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due: ${task.dueDate}'),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: task.getPriorityColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  task.getPriorityText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: task.getPriorityColor(),
                  ),
                ),

                // Show premium badge for premium tasks
                if (AppConfig.hasPremium() && task.attachments != null)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isPastDue
            ? Icon(Icons.warning, color: Colors.red)
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          ).then((updatedTask) {
            if (updatedTask != null) {
              setState(() {
                final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
                if (index != -1) {
                  _tasks[index] = updatedTask;
                }
              });
            }
          });
        },
      ),
    );
  }
}