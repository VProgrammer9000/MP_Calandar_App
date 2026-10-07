import 'package:flutter/material.dart';

import '../utils/dates.dart';

enum PageStep { day, week, month }

// Swipe left/right to move one day, week or month.
// The PageView has no real start, so page 10000 is the date we opened on
// and we count from there.
class CalendarPager extends StatefulWidget {
  final DateTime date;
  final PageStep step;
  final ValueChanged<DateTime> onDateChanged;
  final Widget Function(BuildContext context, DateTime date) builder;

  const CalendarPager({
    super.key,
    required this.date,
    required this.onDateChanged,
    required this.builder,
    this.step = PageStep.day,
  });

  @override
  State<CalendarPager> createState() => _CalendarPagerState();
}

class _CalendarPagerState extends State<CalendarPager> {
  static const _startPage = 10000;

  late final DateTime _startDate = widget.date;
  final _controller = PageController(initialPage: _startPage);

  int _pageFor(DateTime d) {
    switch (widget.step) {
      case PageStep.day:
        return _startPage + daysBetween(_startDate, d);
      case PageStep.week:
        return _startPage +
            daysBetween(startOfWeek(_startDate), startOfWeek(d)) ~/ 7;
      case PageStep.month:
        return _startPage +
            (d.year - _startDate.year) * 12 +
            d.month -
            _startDate.month;
    }
  }

  // move the date by a number of pages
  DateTime _move(DateTime d, int pages) {
    switch (widget.step) {
      case PageStep.day:
        return addDays(d, pages);
      case PageStep.week:
        return addDays(d, pages * 7);
      case PageStep.month:
        return addMonths(d, pages);
    }
  }

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
        if (moved != 0) widget.onDateChanged(_move(widget.date, moved));
      },
      itemBuilder: (context, page) =>
          widget.builder(context, _move(_startDate, page - _startPage)),
    );
  }
}
