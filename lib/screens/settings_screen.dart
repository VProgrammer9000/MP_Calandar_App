import 'package:flutter/material.dart';

// Layout follows wireframe 1m. All values are placeholders for now.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoReschedule = true;
  bool _askBeforeApplying = true;

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
                          'PREFERENCES',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Settings',
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
            _buildSectionTitle('SCHEDULING'),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text('Auto-reschedule'),
              subtitle:
                  const Text('Move flexible tasks when something changes'),
              value: _autoReschedule,
              onChanged: (value) {
                setState(() {
                  _autoReschedule = value;
                });
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: const Text('Ask before applying'),
              subtitle: const Text('Show the new plan before it is saved'),
              value: _askBeforeApplying,
              onChanged: (value) {
                setState(() {
                  _askBeforeApplying = value;
                });
              },
            ),
            const Divider(height: 1),
            _buildValueRow('Block length', '50 min'),
            const Divider(height: 1),
            _buildValueRow('Buffer between blocks', '10 min'),
            _buildSectionTitle('QUIET HOURS'),
            _buildValueRow('From', '22:00'),
            const Divider(height: 1),
            _buildValueRow('To', '07:00'),
            _buildSectionTitle('ACCOUNT'),
            _buildValueRow('Sync university calendar', 'Off'),
            const Divider(height: 1),
            _buildValueRow('Signed in as', 'jane.doe@example.com'),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Text(
                'v0.4 - school project build',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Divider(height: 2, thickness: 2, color: Colors.black),
      ],
    );
  }

  Widget _buildValueRow(String title, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        // TODO: let the user change this value
      },
    );
  }
}
