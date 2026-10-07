import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/dates.dart';

const double hourHeight = 64;
const double hourLabelWidth = 44;

// Scrollable 24 hour column with the events of one day placed on it
class DayTimeline extends StatefulWidget {
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEventTap;

  const DayTimeline({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  State<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<DayTimeline> {
  // start the view around 08:00 like in the wireframe
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
        child: Stack(
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
                left: hourLabelWidth + 4,
                right: 12,
                child: _EventBlock(
                  event: event,
                  onTap: () => widget.onEventTap(event),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HourLine extends StatelessWidget {
  final int hour;

  const HourLine({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: hourLabelWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              twoDigits(hour),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.black12)),
      ],
    );
  }
}

class _EventBlock extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;

  const _EventBlock({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // TODO: long press to drag the block to another time
      onLongPress: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            left: BorderSide(
              color: event.fixed ? Colors.black : Colors.grey.shade500,
              width: 4,
            ),
            top: const BorderSide(color: Colors.black87),
            right: const BorderSide(color: Colors.black87),
            bottom: const BorderSide(color: Colors.black87),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${formatTime(event.start)}-${formatTime(event.end)} · '
              '${event.fixed ? 'fixed' : 'flexible'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
