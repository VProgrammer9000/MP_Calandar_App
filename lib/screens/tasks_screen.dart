import 'package:flutter/material.dart';

// Some fake tasks so the layout has something to show.
// TODO: replace with a real Task model when we add the data part
final List<Map<String, dynamic>> sampleTasks = [
  {
    'title': 'Mobile programming report',
    'description': 'Write the report for the group project',
    'label': 'University',
    'isFixed': false,
    'minutes': 360,
    'done': false,
  },
  {
    'title': 'Study for midterm',
    'description': 'Algorithms chapter 4 to 7',
    'label': 'University',
    'isFixed': false,
    'minutes': 180,
    'done': false,
  },
  {
    'title': 'Shift at the cafe',
    'description': 'Saturday shift',
    'label': 'Work',
    'isFixed': true,
    'minutes': 720,
    'done': false,
  },
  {
    'title': 'Gym',
    'description': 'Leg day',
    'label': 'Health',
    'isFixed': false,
    'minutes': 180,
    'done': true,
  },
  {
    'title': 'Call mom',
    'description': 'Before the weekend',
    'label': 'Personal',
    'isFixed': false,
    'minutes': 15,
    'done': false,
  },
];

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int openCount = 0;
    int openMinutes = 0;
    for (final task in sampleTasks) {
      if (task['done'] == false) {
        openCount++;
        openMinutes += task['minutes'] as int;
      }
    }

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
            // TODO: filters and task list
            const Expanded(child: Center(child: Text('Tasks come here'))),
          ],
        ),
      ),
    );
  }
}
