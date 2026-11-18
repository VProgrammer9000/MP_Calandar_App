import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/sample_data.dart';
import '../models/calendar_event.dart';
import '../services/chat_service.dart';
import '../services/llm_service.dart';
import '../services/storage_service.dart';
import '../utils/dates.dart';
import '../widgets/calendar_pager.dart';
import '../widgets/day_timeline.dart';
import '../widgets/event_detail_sheet.dart';
import '../widgets/month_grid.dart';
import '../widgets/week_day_strip.dart';
import '../widgets/week_timeline.dart';
import 'add_task_screen.dart';
import 'chat_screen.dart';

enum CalendarView { day, week, month }

class CalendarScreen extends StatefulWidget {
  // only used by the tests, so they don't call the real API
  final http.Client? client;

  const CalendarScreen({super.key, this.client});

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

  // TODO: load the user's events, sample events for now
  final List<CalendarEvent> _events = myEvents;

  // shown in the red banner while rescheduling, hidden while null
  String? _rescheduleMessage;
  bool _rescheduling = false;
  // the new plan from the assistant, kept so REVIEW can open it again
  ChatPlan? _reschedulePlan;
  List<Map<String, String>> _rescheduleHistory = [];

  List<CalendarEvent> _eventsFor(DateTime day) =>
      _events.where((e) => isSameDay(e.start, day)).toList();

  List<CalendarEvent> _eventsForMonth(DateTime month) => _events
      .where((e) => e.start.year == month.year && e.start.month == month.month)
      .toList();

  List<CalendarEvent> _eventsForWeek(DateTime weekStart) => _events.where((e) {
        final offset = daysBetween(weekStart, e.start);
        return offset >= 0 && offset < 7;
      }).toList();

  // the detail / edit sheet (1o) opens from the bottom
  void _showEventDetails(CalendarEvent event) {
    showEventDetailSheet(
      context,
      event: event,
      onSave: (updated) {
        setState(() {
          final index = _events.indexOf(event);
          if (index != -1) _events[index] = updated;
        });
        saveData();
      },
      onDelete: () => _deleteEvent(event),
      onReschedule: () => _reschedule(event),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // what we ask the assistant when the user taps Reschedule (1j)
  String _rescheduleRequest(CalendarEvent event) {
    final now = '${formatShortDate(event.start)} '
        '${formatTime(event.start)}-${formatTime(event.end)}';
    var request = 'Find a new time for "${event.title}" (now $now). '
        'Keep the same length.';
    if (event.windowStart != null && event.windowEnd != null) {
      request += ' Pick a time between '
          '${formatShortDate(event.windowStart!)} ${formatTime(event.windowStart!)} and '
          '${formatShortDate(event.windowEnd!)} ${formatTime(event.windowEnd!)}, '
          'not in the past.';
    } else {
      request += ' Pick a time in the next 7 days, not in the past.';
    }
    return request;
  }

  Future<void> _reschedule(CalendarEvent event) async {
    if (event.fixed) {
      _showMessage('Fixed events can\'t be moved');
      return;
    }
    if (_rescheduling) return;

    final request = _rescheduleRequest(event);
    setState(() {
      _rescheduling = true;
      _reschedulePlan = null;
      _rescheduleMessage = 'Finding a new time for "${event.title}"';
    });

    try {
      final plan = await planChanges(request, _events, client: widget.client);
      if (!mounted) return;
      if (plan.changes.isEmpty) {
        // the assistant could not find a time, the reply says why
        setState(() {
          _rescheduling = false;
          _rescheduleMessage = null;
        });
        _showMessage(plan.reply);
        return;
      }
      setState(() {
        _rescheduling = false;
        _reschedulePlan = plan;
        _rescheduleHistory = [
          {'role': 'user', 'content': request},
          {'role': 'assistant', 'content': plan.reply},
        ];
        _rescheduleMessage = 'A new time for "${event.title}" is ready';
      });
      await _openReschedulePlan();
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _rescheduling = false;
        _rescheduleMessage = null;
      });
      _showMessage(e.message);
    }
  }

  // the review page from the chat, with Accept / Reject and refine
  Future<void> _openReschedulePlan() async {
    final result = await Navigator.push<(bool, ChatPlan)>(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePreviewScreen(
          plan: _reschedulePlan!,
          history: _rescheduleHistory,
          client: widget.client,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      // going back without deciding keeps the banner, so it can be reviewed later
      if (result != null) {
        _reschedulePlan = null;
        _rescheduleMessage = null;
      }
    });
  }

  Future<void> _openAddTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(type: AddType.event),
      ),
    );
    // The add screen updates myEvents in calendar mode.
    setState(() {});
    saveData();
  }

  void _deleteEvent(CalendarEvent event) {
    final index = _events.indexOf(event);
    setState(() => _events.remove(event));
    saveData();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${event.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _events.insert(index, event));
            saveData();
          },
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
        onPressed: _openAddTask,
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
              padding: const EdgeInsets.only(
                left: hourLabelWidth,
                right: weekGridRightPadding,
              ),
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
          if (_rescheduling)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              onPressed: _openReschedulePlan,
              child: const Text('REVIEW'),
            ),
        ],
      ),
    );
  }
}
