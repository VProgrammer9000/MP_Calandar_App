import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/dates.dart';
import 'day_timeline.dart';

// space on the right of the grid, the day strip above uses the same
const double weekGridRightPadding = 8;

// Scrollable 24 hour grid with one column per day, monday to sunday
class WeekTimeline extends StatefulWidget {
  final DateTime weekStart;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEventTap;

  const WeekTimeline({
    super.key,
    required this.weekStart,
    required this.events,
    required this.onEventTap,
  });

  @override
  State<WeekTimeline> createState() => _WeekTimelineState();
}

class _WeekTimelineState extends State<WeekTimeline> {
  final _scrollController = ScrollController(
    initialScrollOffset: 8 * hourHeight,
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _minutesToY(DateTime d) => (d.hour * 60 + d.minute) / 60 * hourHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: 24 * hourHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth =
                (constraints.maxWidth - hourLabelWidth - weekGridRightPadding) /
                    7;

            return Stack(
              children: [
                for (var hour = 0; hour < 24; hour++)
                  Positioned(
                    top: hour * hourHeight,
                    left: 0,
                    right: 0,
                    child: HourLine(hour: hour),
                  ),
                for (final event in widget.events)
                  Positioned(
                    top: _minutesToY(event.start),
                    height: _minutesToY(event.end) - _minutesToY(event.start),
                    left: hourLabelWidth +
                        daysBetween(widget.weekStart, event.start) *
                            columnWidth +
                        2,
                    width: columnWidth - 4,
                    child: _WeekEventBlock(
                      event: event,
                      onTap: () => widget.onEventTap(event),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeekEventBlock extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;

  const _WeekEventBlock({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black87),
        shape: const RoundedRectangleBorder(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            color: event.fixed ? Colors.black : Colors.grey.shade500,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 3, 1, 3),
              child: Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
