import 'package:flutter/material.dart';

import '../utils/dates.dart';

// Swipe left/right to move one day (or one week if weekly is true).
// The PageView has no real start, so page 10000 is the date we opened on
// and we count from there.
class CalendarPager extends StatefulWidget {
  final DateTime date;
  final bool weekly;
  final ValueChanged<DateTime> onDateChanged;
  final Widget Function(BuildContext context, DateTime date) builder;

  const CalendarPager({
    super.key,
    required this.date,
    required this.onDateChanged,
    required this.builder,
    this.weekly = false,
  });

  @override
  State<CalendarPager> createState() => _CalendarPagerState();
}

class _CalendarPagerState extends State<CalendarPager> {
  static const _startPage = 10000;

  late final DateTime _startDate = widget.date;
  final _controller = PageController(initialPage: _startPage);

  int get _step => widget.weekly ? 7 : 1;

  int _pageFor(DateTime d) {
    if (widget.weekly) {
      return _startPage +
          daysBetween(startOfWeek(_startDate), startOfWeek(d)) ~/ 7;
    }
    return _startPage + daysBetween(_startDate, d);
  }

  DateTime _dateFor(int page) =>
      addDays(_startDate, (page - _startPage) * _step);

  @override
  void didUpdateWidget(CalendarPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // date was changed from outside (chip or today button), so jump there
    final target = _pageFor(widget.date);
    if (_controller.hasClients && _controller.page?.round() != target) {
      _controller.jumpToPage(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      onPageChanged: (page) {
        final moved = page - _pageFor(widget.date);
        if (moved != 0) {
          widget.onDateChanged(addDays(widget.date, moved * _step));
        }
      },
      itemBuilder: (context, page) => widget.builder(context, _dateFor(page)),
    );
  }
}
