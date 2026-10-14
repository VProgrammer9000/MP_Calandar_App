import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/dates.dart';

const _maxBarsPerDay = 3;

// Monday-first grid for one month, each day shows a bar per event
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayLongPress;

  const MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.events,
    required this.onDayTap,
    required this.onDayLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final dayCount = daysInMonth(month);
    // empty cells before the 1st so it lands under the right weekday
    final blanks = first.weekday - 1;
    final rows = ((blanks + dayCount) / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (final name in weekdayNames)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      name[0],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellHeight = (constraints.maxHeight / rows).clamp(
                  0.0,
                  80.0,
                );

                return Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.black12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var row = 0; row < rows; row++)
                          SizedBox(
                            height: cellHeight,
                            child: Row(
                              children: [
                                for (var col = 0; col < 7; col++)
                                  Expanded(
                                    child:
                                        _buildCell(row * 7 + col - blanks + 1),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int dayNumber) {
    if (dayNumber < 1 || dayNumber > daysInMonth(month)) {
      return Container(decoration: _cellBorder());
    }

    final day = DateTime(month.year, month.month, dayNumber);
    final dayEvents = events.where((e) => isSameDay(e.start, day)).toList();

    return _MonthDayCell(
      day: day,
      isToday: isSameDay(day, today),
      events: dayEvents,
      decoration: _cellBorder(),
      onTap: () => onDayTap(day),
      onLongPress: () => onDayLongPress(day),
    );
  }

  BoxDecoration _cellBorder() => const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      );
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<CalendarEvent> events;
  final BoxDecoration decoration;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MonthDayCell({
    required this.day,
    required this.isToday,
    required this.events,
    required this.decoration,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        // cut off bars that don't fit on small screens
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        decoration: decoration.copyWith(
          color: isToday ? Colors.red.shade50 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            for (final event in events.take(_maxBarsPerDay))
              Container(
                height: 4,
                margin: const EdgeInsets.only(bottom: 3),
                color: event.fixed ? Colors.black87 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
