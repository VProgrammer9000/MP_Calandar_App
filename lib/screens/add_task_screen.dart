import 'package:flutter/material.dart';

import '../widgets/add_by_prompt.dart';

enum AddMode { prompt, form }

// "Add to my week", lets the user add a task by text prompt or by form
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  AddMode _mode = AddMode.prompt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SegmentedButton<AddMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AddMode.prompt,
                    label: Text('Text prompt'),
                  ),
                  ButtonSegment(value: AddMode.form, label: Text('Form')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.black,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
            Expanded(
              child: _mode == AddMode.prompt
                  ? const AddByPrompt()
                  // TODO: add by form (1h)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add to my week',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black54),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
