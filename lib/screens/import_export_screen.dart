import 'package:flutter/material.dart';

// Layout follows wireframe 1n. All calendars are placeholders for now.
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

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
                          'CALENDAR DATA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Import & export',
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
            _buildSectionTitle('CONNECTED'),
            _buildCalendarRow(
              'University timetable',
              'Synced 5 min ago',
              'live',
              Colors.black,
            ),
            const Divider(height: 1),
            _buildCalendarRow(
              'Work shifts (.ics)',
              'Imported Sep 28',
              'manual',
              Colors.grey.shade600,
            ),
            const Divider(height: 1),
            _buildCalendarRow(
              'Google Calendar',
              'Not connected',
              'connect',
              Colors.grey.shade300,
            ),
            const Divider(height: 1),
            _buildSectionTitle('IMPORT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop an .ics / .csv file',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      'Events are added to your calendar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: OutlinedButton(
                style: _buttonStyle(),
                onPressed: () {
                  // TODO: pick a file and import it
                },
                child:
                    const Text('Choose a file', style: TextStyle(fontSize: 16)),
              ),
            ),
            _buildSectionTitle('EXPORT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildExportButton('.ics'),
                  const SizedBox(width: 8),
                  _buildExportButton('.csv'),
                  const SizedBox(width: 8),
                  _buildExportButton('json'),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Exports the visible range',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: const RoundedRectangleBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignment: Alignment.centerLeft,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.red,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCalendarRow(
    String name,
    String status,
    String action,
    Color color,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(width: 4, height: 40, color: color),
      title: Text(name),
      subtitle: Text(status, style: const TextStyle(color: Colors.grey)),
      trailing: Text(action, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        // TODO: manage this calendar
      },
    );
  }

  Widget _buildExportButton(String format) {
    return Expanded(
      child: OutlinedButton(
        style: _buttonStyle().copyWith(
          alignment: Alignment.center,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        onPressed: () {
          // TODO: export the calendar as this format
        },
        child: Text(format),
      ),
    );
  }
}
