import 'package:flutter/material.dart';

// Lets a chat bubble pop in like a text message. The space for it opens up
// first so the messages above move up smoothly, then the bubble grows out of
// the corner it was sent from with a small overshoot.
class MessageAppear extends StatefulWidget {
  final Widget child;
  // the user's messages come from the right, the assistant's from the left
  final bool fromRight;
  // false for messages that were already there, e.g. after switching tabs
  final bool animate;

  const MessageAppear({
    super.key,
    required this.child,
    required this.fromRight,
    this.animate = true,
  });

  @override
  State<MessageAppear> createState() => _MessageAppearState();
}

class _MessageAppearState extends State<MessageAppear>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.animate ? 0 : 1,
  );

  late final _size = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .6, curve: Curves.easeOutCubic),
  );
  late final _scale = Tween<double>(begin: .5, end: 1).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(.1, 1, curve: Curves.easeOutBack),
  ));
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.1, .5, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment:
              widget.fromRight ? Alignment.bottomRight : Alignment.bottomLeft,
          child: widget.child,
        ),
      ),
    );
  }
}
