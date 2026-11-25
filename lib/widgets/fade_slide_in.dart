import 'package:flutter/material.dart';

// Opens up from zero height and fades in the first time it is shown, so the
// rows below slide down instead of jumping. With animate false it just
// shows the child, so only new rows get the animation.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final bool animate;

  const FadeSlideIn({super.key, required this.child, this.animate = true});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: widget.animate ? 0 : 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
