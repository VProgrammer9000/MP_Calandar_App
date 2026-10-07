import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../utils/dates.dart';
import '../widgets/day_timeline.dart';
import '../widgets/week_day_strip.dart';

enum CalendarView { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // the PageView has no real start, so page 10000 is today and we count from there
  static const _todayPage = 10000;

  final _today = dateOnly(DateTime.now());
  final _pageController = PageController(initialPage: _todayPage);
  late DateTime _selectedDay = _today;
  CalendarView _view = CalendarView.day;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dayForPage(int page) =>
      DateTime(_today.year, _today.month, _today.day + page - _todayPage);

  int _pageForDay(DateTime day) =>
      _todayPage +
      DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime.utc(_today.year, _today.month, _today.day)).inDays;

  void _goToDay(DateTime day) {
    setState(() => _selectedDay = day);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_pageForDay(day));
    }
  }

  // TODO: load the user's events
  final List<CalendarEvent> _events = [];

  // TODO: filled in by the smart rescheduler, banner is hidden while null
  String? _rescheduleMessage;

  List<CalendarEvent> _eventsFor(DateTime day) =>
      _events.where((e) => isSameDay(e.start, day)).toList();

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
            if (_view == CalendarView.day) ...[
              WeekDayStrip(selectedDay: _selectedDay, onDaySelected: _goToDay),
              const Divider(height: 1),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() => _selectedDay = _dayForPage(page));
                  },
                  itemBuilder: (context, page) => DayTimeline(
                    events: _eventsFor(_dayForPage(page)),
                    onEventTap: _showEventDetails,
                  ),
                ),
              ),
            ] else
              // TODO: week (1d) and month (1e) views
              const Expanded(child: SizedBox()),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekLabel(_selectedDay),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weekdayNames[_selectedDay.weekday - 1]} ${_selectedDay.day}',
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
