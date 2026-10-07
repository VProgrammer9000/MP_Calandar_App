import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/dates.dart';
import '../widgets/calendar_pager.dart';
import '../widgets/day_timeline.dart';
import '../widgets/month_grid.dart';
import '../widgets/week_day_strip.dart';
import '../widgets/week_timeline.dart';

enum CalendarView { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _today = dateOnly(DateTime.now());
  late DateTime _selectedDay = _today;
  CalendarView _view = CalendarView.day;

  // fingers on the screen, used to detect a pinch
  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _pointerStarts = {};
  double? _pinchStartDistance;

  void _goToDay(DateTime day) {
    setState(() => _selectedDay = day);
  }

  double _pointerDistance() =>
      (_pointers.values.first - _pointers.values.last).distance;

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    _pointerStarts[e.pointer] = e.position;
    if (_pointers.length == 2) _pinchStartDistance = _pointerDistance();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointers.containsKey(e.pointer)) _pointers[e.pointer] = e.position;
  }

  // pinch out zooms in (month -> week -> day), pinch in zooms out
  void _onPointerUp(PointerEvent e) {
    // both fingers have to move, so a finger that got stuck can't make
    // a normal swipe count as a pinch
    final bothMoved = _pointers.keys.every(
      (id) => (_pointers[id]! - _pointerStarts[id]!).distance > 10,
    );
    if (_pointers.length == 2 && _pinchStartDistance != null && bothMoved) {
      final scale = _pointerDistance() / _pinchStartDistance!;
      if (scale > 1.4) _zoom(-1);
      if (scale < 0.7) _zoom(1);
    }
    _pointers.remove(e.pointer);
    _pointerStarts.remove(e.pointer);
    if (_pointers.length < 2) _pinchStartDistance = null;
  }

  void _zoom(int step) {
    final index = (_view.index + step).clamp(0, CalendarView.values.length - 1);
    setState(() => _view = CalendarView.values[index]);
  }

  // TODO: load the user's events
  final List<CalendarEvent> _events = [];

  // TODO: filled in by the smart rescheduler, banner is hidden while null
  String? _rescheduleMessage;

  List<CalendarEvent> _eventsFor(DateTime day) =>
      _events.where((e) => isSameDay(e.start, day)).toList();

  List<CalendarEvent> _eventsForMonth(DateTime month) => _events
      .where((e) => e.start.year == month.year && e.start.month == month.month)
      .toList();

  List<CalendarEvent> _eventsForWeek(DateTime weekStart) => _events.where((e) {
        final offset = daysBetween(weekStart, e.start);
        return offset >= 0 && offset < 7;
      }).toList();

  void _showEventDetails(CalendarEvent event) {
    // TODO: real detail / edit sheet (1o)
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${formatTime(event.start)}-${formatTime(event.end)}'),
            Text(event.fixed ? 'Fixed' : 'Flexible'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 2, color: Colors.black),
            _buildViewSwitcher(),
            if (_rescheduleMessage != null)
              _buildRescheduleBanner(_rescheduleMessage!),
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: _buildView(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        // TODO: open add task (by prompt or form)
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildView() {
    switch (_view) {
      case CalendarView.day:
        return Column(
          children: [
            WeekDayStrip(selectedDay: _selectedDay, onDaySelected: _goToDay),
            const Divider(height: 1),
            Expanded(
              child: CalendarPager(
                key: const ValueKey(CalendarView.day),
                date: _selectedDay,
                onDateChanged: _goToDay,
                builder: (context, day) => DayTimeline(
                  events: _eventsFor(day),
                  onEventTap: _showEventDetails,
                ),
              ),
            ),
          ],
        );
      case CalendarView.week:
        return Column(
          children: [
            // tapping a day in the week opens it in the day view
            WeekDayStrip(
              selectedDay: _selectedDay,
              onDaySelected: (day) {
                setState(() {
                  _selectedDay = day;
                  _view = CalendarView.day;
                });
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: CalendarPager(
                key: const ValueKey(CalendarView.week),
                date: _selectedDay,
                step: PageStep.week,
                onDateChanged: _goToDay,
                builder: (context, day) {
                  final weekStart = startOfWeek(day);
                  return WeekTimeline(
                    weekStart: weekStart,
                    events: _eventsForWeek(weekStart),
                    onEventTap: _showEventDetails,
                  );
                },
              ),
            ),
          ],
        );
      case CalendarView.month:
        return CalendarPager(
          key: const ValueKey(CalendarView.month),
          date: _selectedDay,
          step: PageStep.month,
          onDateChanged: _goToDay,
          builder: (context, day) => MonthGrid(
            month: day,
            today: _today,
            events: _eventsForMonth(day),
            onDayTap: (day) {
              setState(() {
                _selectedDay = day;
                _view = CalendarView.day;
              });
            },
            // TODO: quick add a task on that day
            onDayLongPress: (day) {},
          ),
        );
    }
  }

  // small text above the title, e.g. "WEEK 38 · SEP 14 - 20"
  String _headerLabel() {
    switch (_view) {
      case CalendarView.day:
        return weekLabel(_selectedDay);
      case CalendarView.week:
        return 'WEEK ${weekNumber(_selectedDay)}';
      case CalendarView.month:
        return '${_selectedDay.year}';
    }
  }

  String _headerTitle() {
    switch (_view) {
      case CalendarView.day:
        return '${weekdayNames[_selectedDay.weekday - 1]} ${_selectedDay.day}';
      case CalendarView.week:
        return weekRange(_selectedDay);
      case CalendarView.month:
        return monthFullNames[_selectedDay.month - 1];
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headerLabel(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _headerTitle(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          SegmentedButton<CalendarView>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: CalendarView.day, label: Text('Day')),
              ButtonSegment(value: CalendarView.week, label: Text('Week')),
              ButtonSegment(value: CalendarView.month, label: Text('Month')),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              setState(() => _view = selection.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.black,
              selectedForegroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              shape: const RoundedRectangleBorder(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_outlined),
            onPressed: () => _goToDay(_today),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleBanner(String message) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade700)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            // TODO: open smart reschedule (1j)
            onPressed: () {},
            child: const Text('REVIEW'),
          ),
        ],
      ),
    );
  }
}
