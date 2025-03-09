import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/task.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskPriority _selectedPriority;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: _task.title);
    _descriptionController = TextEditingController(text: _task.description);
    _selectedDate = _task.dueDate;
    _selectedPriority = _task.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTask() {
    final updatedTask = _task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDate,
      priority: _selectedPriority,
    );

    Navigator.pop(context, updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task status
            Row(
              children: [
                Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Checkbox(
                  value: _task.isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _task = _task.copyWith(isCompleted: value);
                    });
                  },
                ),
                Text(_task.isCompleted ? 'Completed' : 'Pending'),
              ],
            ),
            SizedBox(height: 16),

            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),

            // Due date picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Due Date: ${_selectedDate}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Change'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Priority dropdown
            Row(
              children: [
                Text('Priority:', style: TextStyle(fontSize: 16)),
                SizedBox(width: 16),
                DropdownButton<TaskPriority>(
                  value: _selectedPriority,
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem<TaskPriority>(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Task(
                                id: '',
                                title: '',
                                description: '',
                                dueDate: DateTime.now(),
                                priority: priority,
                              ).getPriorityColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(priority.toString().split('.').last.capitalize()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
              ],
            ),

            // Premium features section
            if (AppConfig.enablePremiumFeatures)
              _buildPremiumFeatures(),

            SizedBox(height: 48), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.star, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Premium Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Attachments section
        ListTile(
          leading: Icon(Icons.attach_file),
          title: Text('Add Attachments'),
          subtitle: Text(
            _task.attachments?.isNotEmpty == true
                ? '${_task.attachments!.length} attachments'
                : 'No attachments',
          ),
          trailing: Icon(Icons.add),
          onTap: () {
            // Would open attachment picker in a real app
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attachment feature would open here')),
            );
          },
        ),

        // Assign users section
        ListTile(
          leading: Icon(Icons.person_add),
          title: Text('Assign Users'),
          subtitle: Text(
            _task.assignedUsers?.isNotEmpty == true
                ? '${_task.assignedUsers!.length} users assigned'
                : 'No users assigned',
          ),
          trailing: Icon(Icons.add),
          onTap: () {
            // Would open user picker in a real app
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User assignment would open here')),
            );
          },
        ),

        // Set reminders section
        ListTile(
          leading: Icon(Icons.notification_add),
          title: Text('Set Reminders'),
          subtitle: Text('Add reminders for this task'),
          trailing: Icon(Icons.add),
          onTap: () {
            // Show reminder dialog if notifications are enabled
            if (AppConfig.enableNotifications) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reminder dialog would open here')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications are disabled')),
              );
            }
          },
        ),
      ],
    );
  }
}

// Extension to capitalize string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}