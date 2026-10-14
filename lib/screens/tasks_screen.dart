import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/task.dart';
import '../models/task_draft.dart';
import '../utils/dates.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final filters = ['All', 'Flexible', 'Fixed', 'Due'];
  String selectedFilter = 'All';

  // 360 -> "6h", 90 -> "1h 30m", 15 -> "15m"
  String formatLength(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    if (minutes % 60 == 0) {
      return '${minutes ~/ 60}h';
    }
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  // the tasks to show for the selected filter
  List<Task> visibleTasks() {
    if (selectedFilter == 'Flexible') {
      return myTasks.where((task) => !task.fixed).toList();
    }
    if (selectedFilter == 'Fixed') {
      return myTasks.where((task) => task.fixed).toList();
    }
    if (selectedFilter == 'Due') {
      // only tasks with a deadline, the closest one first
      final due = myTasks.where((task) => task.deadline != null).toList();
      due.sort((a, b) => a.deadline!.compareTo(b.deadline!));
      return due;
    }
    return myTasks;
  }

  Future<void> openAddTask() async {
    // the form gives back a TaskDraft when the user taps "Schedule it"
    final draft = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (draft is TaskDraft) {
      setState(() {
        myTasks.insert(0, Task.fromDraft(draft));
      });
    }
  }

  void deleteTask(Task task) {
    final index = myTasks.indexOf(task);
    setState(() {
      myTasks.remove(task);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              myTasks.insert(index, task);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int openCount = 0;
    int openMinutes = 0;
    for (final task in myTasks) {
      if (!task.done) {
        openCount++;
        openMinutes += task.minutes;
      }
    }

    final tasks = visibleTasks();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$openCount OPEN · ${openMinutes ~/ 60} H TO PLACE',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tasks',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            buildFilterRow(),
            Divider(height: 1, color: Colors.grey.shade300),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        return buildTaskTile(tasks[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        onPressed: openAddTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: filter == selectedFilter,
                showCheckmark: false,
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: filter == selectedFilter ? Colors.white : Colors.black,
                ),
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey),
                ),
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTaskTile(Task task) {
    // swipe left to delete
    return Dismissible(
      key: ObjectKey(task),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) => deleteTask(task),
      child: CheckboxListTile(
        value: task.done,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onChanged: (value) {
          setState(() {
            task.done = value ?? false;
          });
        },
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            // done tasks are crossed out
            color: task.done ? Colors.grey : Colors.black,
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(task.description, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 8),
            // Wrap so the tags go to a new line on small screens
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (task.label != null) buildTag(task.label!, Colors.white),
                buildTag(task.fixed ? 'Fixed' : 'Flexible', Colors.grey.shade200),
                if (task.deadline != null)
                  buildTag('Due ${formatShortDate(task.deadline!)}', Colors.white),
              ],
            ),
          ],
        ),
        secondary: Text(
          formatLength(task.minutes),
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // Small box with a border, used for the label and the flexible/fixed type
  Widget buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
