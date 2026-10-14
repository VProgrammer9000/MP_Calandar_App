import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/task_draft.dart';
import '../models/task_label.dart';
import '../utils/dates.dart';

// Opens the detail / edit sheet (1o) from the bottom of the screen.
void showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required ValueChanged<CalendarEvent> onSave,
  required VoidCallback onDelete,
  required VoidCallback onReschedule,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(),
    builder: (context) => EventDetailSheet(
      event: event,
      onSave: onSave,
      onDelete: onDelete,
      onReschedule: onReschedule,
    ),
  );
}

class EventDetailSheet extends StatefulWidget {
  final CalendarEvent event;
  final ValueChanged<CalendarEvent> onSave;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;

  const EventDetailSheet({
    super.key,
    required this.event,
    required this.onSave,
    required this.onDelete,
    required this.onReschedule,
  });

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  // lengths the user can pick, in minutes
  final lengthOptions = [15, 30, 45, 60, 90, 120, 180, 240, 360, 480];

  // copies of the event values that the user can change before saving
  late DateTime start;
  late int minutes;
  late String? label;
  late Priority priority;
  late DateTime? windowStart;
  late DateTime? windowEnd;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    start = event.start;
    minutes = event.end.difference(event.start).inMinutes;
    label = event.label;
    priority = event.priority;
    windowStart = event.windowStart;
    windowEnd = event.windowEnd;
    if (!lengthOptions.contains(minutes)) {
      lengthOptions.add(minutes);
      lengthOptions.sort();
    }
  }

  DateTime get end => start.add(Duration(minutes: minutes));

  // same size as the plain text rows
  final rowTextStyle = const TextStyle(fontSize: 14, color: Colors.black);

  String priorityName(Priority p) {
    switch (p) {
      case Priority.high:
        return 'High';
      case Priority.normal:
        return 'Normal';
      case Priority.low:
        return 'Low';
    }
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (picked == null) return;
    setState(() {
      start = DateTime(start.year, start.month, start.day, picked.hour, picked.minute);
    });
  }

  Future<void> pickWindow() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: addDays(today, -365),
      lastDate: addDays(today, 365 * 2),
      initialDateRange: windowStart != null && windowEnd != null
          ? DateTimeRange(start: windowStart!, end: windowEnd!)
          : null,
    );
    if (picked == null) return;
    setState(() {
      windowStart = picked.start;
      windowEnd = picked.end;
    });
  }

  void save() {
    widget.onSave(CalendarEvent(
      title: widget.event.title,
      start: start,
      end: end,
      fixed: widget.event.fixed,
      label: label,
      priority: priority,
      windowStart: windowStart,
      windowEnd: windowEnd,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final type = event.fixed ? 'FIXED' : 'FLEXIBLE';
    final topLine = label == null ? type : '$type · ${label!.toUpperCase()}';

    String windowText;
    if (event.fixed) {
      windowText = 'Fixed time';
    } else if (windowStart == null || windowEnd == null) {
      windowText = 'Any time';
    } else {
      windowText = '${formatShortDate(windowStart!)} - ${formatShortDate(windowEnd!)}';
    }

    return Container(
      // red line on top like in the wireframe
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.red.shade700, width: 3)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topLine,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildRow(
                'when',
                InkWell(
                  onTap: pickStartTime,
                  child: Text(
                    '${formatShortDate(start)} · ${formatTime(start)}-${formatTime(end)}',
                  ),
                ),
              ),
              buildRow(
                'length',
                DropdownButton<int>(
                  value: minutes,
                  isDense: true,
                  underline: const SizedBox(),
                  style: rowTextStyle,
                  items: [
                    for (final option in lengthOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(formatDuration(Duration(minutes: option))),
                      ),
                  ],
                  onChanged: (value) => setState(() => minutes = value!),
                ),
              ),
              buildRow(
                'window',
                InkWell(
                  onTap: event.fixed ? null : pickWindow,
                  child: Text(windowText),
                ),
              ),
              buildRow(
                'priority',
                DropdownButton<Priority>(
                  value: priority,
                  isDense: true,
                  underline: const SizedBox(),
                  style: rowTextStyle,
                  items: [
                    for (final p in Priority.values)
                      DropdownMenuItem(value: p, child: Text(priorityName(p))),
                  ],
                  onChanged: (value) => setState(() => priority = value!),
                ),
              ),
              buildRow(
                'label',
                DropdownButton<String?>(
                  value: label,
                  isDense: true,
                  underline: const SizedBox(),
                  style: rowTextStyle,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No label')),
                    for (final l in defaultLabels)
                      DropdownMenuItem(
                        value: l.name,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, color: l.color),
                            const SizedBox(width: 6),
                            Text(l.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => label = value),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: save,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReschedule();
                      },
                      child: const Text('Reschedule'),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                  child: const Text('Delete task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // one line like "length    1h 30m" with a line under it
  Widget buildRow(String name, Widget value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: value),
          ),
        ],
      ),
    );
  }
}
