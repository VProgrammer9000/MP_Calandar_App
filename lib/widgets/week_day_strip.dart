import 'package:flutter/material.dart';

import '../utils/dates.dart';

// Row of choice chips MON-SUN for the week of the selected day
class WeekDayStrip extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  // space on the left and right of the row. The week view uses the hour label
  // width here so every day lines up with its column in the grid below
  final EdgeInsets padding;

  const WeekDayStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    final monday = startOfWeek(selectedDay);

    final selectedIndex = daysBetween(monday, selectedDay);

    return Padding(
      padding: padding.add(const EdgeInsets.symmetric(vertical: 8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;

          return Stack(
            children: [
              // the black box slides to the selected day instead of jumping
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * cellWidth + 2,
                width: cellWidth - 4,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // chips sit on a surface in the theme's background colour,
              // which would hide the sliding box behind them
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                ),
                child: Row(
                  children: List.generate(7, (i) {
                    final day = addDays(monday, i);
                    final selected = i == selectedIndex;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => onDaySelected(day),
                          // see through, the sliding box behind is the highlight
                          color: const WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          pressElevation: 0,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          labelPadding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black54,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: [
                                  Text(
                                    weekdayNames[i]
                                        .substring(0, 3)
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
