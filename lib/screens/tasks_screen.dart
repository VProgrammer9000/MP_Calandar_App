import 'package:flutter/material.dart';

// Some fake tasks so the layout has something to show.
// TODO: replace with a real Task model when we add the data part
final List<Map<String, dynamic>> sampleTasks = [
  {
    'title': 'Task title',
    'description': 'Description',
    'label': 'University',
    'isFixed': false,
    'minutes': 360,
    'done': false,
  },
  {
    'title': 'Task title',
    'description': 'Description',
    'label': 'University',
    'isFixed': false,
    'minutes': 180,
    'done': false,
  },
  {
    'title': 'Task title',
    'description': 'Description',
    'label': 'Work',
    'isFixed': true,
    'minutes': 720,
    'done': false,
  },
  {
    'title': 'Task title',
    'description': 'Description',
    'label': 'Health',
    'isFixed': false,
    'minutes': 180,
    'done': true,
  },
  {
    'title': 'Task title',
    'description': 'Description',
    'label': 'Personal',
    'isFixed': false,
    'minutes': 15,
    'done': false,
  },
];

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  // 360 -> "6h", 15 -> "15m"
  String formatLength(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    return '${minutes ~/ 60}h';
  }

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
            buildFilterRow(),
            Divider(height: 1, color: Colors.grey.shade300),
            Expanded(
              child: ListView.separated(
                itemCount: sampleTasks.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  return buildTaskTile(sampleTasks[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterRow() {
    final filters = ['All', 'Flexible', 'Fixed', 'Due'];

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
                // only "All" is selected for now
                selected: filter == 'All',
                showCheckmark: false,
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: filter == 'All' ? Colors.white : Colors.black,
                ),
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey),
                ),
                onSelected: (selected) {
                  // TODO: filter the list
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTaskTile(Map<String, dynamic> task) {
    return CheckboxListTile(
      value: task['done'],
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onChanged: (value) {
        // TODO: mark the task as done
      },
      title: Text(
        task['title'],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(task['description'], style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              buildTag(task['label'], Colors.white),
              const SizedBox(width: 6),
              buildTag(
                task['isFixed'] ? 'Fixed' : 'Flexible',
                Colors.grey.shade200,
              ),
            ],
          ),
        ],
      ),
      secondary: Text(
        formatLength(task['minutes']),
        style: const TextStyle(color: Colors.grey),
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
