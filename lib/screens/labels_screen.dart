import 'package:flutter/material.dart';

// Layout follows wireframe 1k. All labels are placeholders for now.
class LabelsScreen extends StatelessWidget {
  const LabelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4 LABELS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Labels',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey, width: 2),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
            const Divider(height: 2, thickness: 2, color: Colors.black),
            _buildLabelRow(
                'University', 'Weekdays 08:00 - 18:00', Colors.black),
            const Divider(height: 1),
            _buildLabelRow('Work', 'Min 30 min gap', Colors.grey.shade600),
            const Divider(height: 1),
            _buildLabelRow('Health', 'Mornings only', Colors.grey.shade400),
            const Divider(height: 1),
            _buildLabelRow('Personal', 'Never move', Colors.red),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  // TODO: open a form for a new label
                },
                child:
                    const Text('+ New label', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Each label carries a scheduling rule (time window, min gap, never-move)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String name, String rule, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(width: 24, height: 24, color: color),
      title: Text(name),
      subtitle: Text(rule, style: const TextStyle(color: Colors.grey)),
      trailing: const Text('edit', style: TextStyle(color: Colors.grey)),
      onTap: () {
        // TODO: edit the label and its rule
      },
    );
  }
}
