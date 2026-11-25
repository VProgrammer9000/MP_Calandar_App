import 'dart:math';

import 'package:flutter/material.dart';

// Three dots that bounce one after the other, shown while the assistant is
// writing its answer
class TypingDots extends StatefulWidget {
  final Color color;

  const TypingDots({super.key, this.color = const Color(0xff616161)});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 0 when the dot is resting, 1 at the top of its bounce. Each dot starts a
  // bit after the one before it and rests for the second half of the loop.
  double _lift(int dot) {
    final t = (_controller.value - dot * .15) % 1;
    if (t > .5) return 0;
    return sin(t / .5 * pi);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'The assistant is typing',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                child: Transform.translate(
                  offset: Offset(0, -4 * _lift(i)),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: .4 + .6 * _lift(i)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
