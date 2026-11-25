import 'package:flutter/material.dart';

// Text that slides and fades to its new value when it changes.
// direction 1 slides the new text up from below (going forward in time),
// -1 slides it down from above (going back).
class SlidingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int direction;

  const SlidingText(
    this.text, {
    super.key,
    required this.style,
    this.direction = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          // the new text comes in from one side, the old one leaves on the
          // other side
          final incoming = child.key == ValueKey(text);
          final from = Offset(0, (incoming ? 0.6 : -0.6) * direction);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: from, end: Offset.zero).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(text, key: ValueKey(text), style: style),
      ),
    );
  }
}
