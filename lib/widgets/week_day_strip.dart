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

    return Padding(
      padding: padding.add(const EdgeInsets.symmetric(vertical: 8)),
      child: Row(
        children: List.generate(7, (i) {
          final day = DateTime(monday.year, monday.month, monday.day + i);
          final selected = isSameDay(day, selectedDay);
          final textColor = selected ? Colors.white : Colors.black54;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => onDaySelected(day),
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                labelPadding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        weekdayNames[i].substring(0, 3).toUpperCase(),
                        style: TextStyle(fontSize: 11, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(fontSize: 15, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
