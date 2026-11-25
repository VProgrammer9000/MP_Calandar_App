import 'dart:async';

import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

const _moveDuration = Duration(milliseconds: 300);
const _fadeDuration = Duration(milliseconds: 250);

// Places the event blocks and animates them: new blocks fade in, moved or
// resized blocks slide to their new place, deleted blocks fade out.
// Blocks that are already there when the page opens don't animate, so
// swiping between days stays calm.
class AnimatedEventStack extends StatefulWidget {
  final List<CalendarEvent> events;
  // where a block goes, given the size of the stack
  final Rect Function(CalendarEvent event, Size size) rectFor;
  final Widget Function(CalendarEvent event) builder;

  const AnimatedEventStack({
    super.key,
    required this.events,
    required this.rectFor,
    required this.builder,
  });

  @override
  State<AnimatedEventStack> createState() => _AnimatedEventStackState();
}

class _AnimatedEventStackState extends State<AnimatedEventStack> {
  // added after the page was built, these get the fade in
  final Set<String> _entering = {};
  // removed blocks stay here while they fade out
  final Map<String, CalendarEvent> _leaving = {};
  final Map<String, Timer> _leaveTimers = {};

  @override
  void didUpdateWidget(AnimatedEventStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = {for (final e in oldWidget.events) e.id};
    final newIds = {for (final e in widget.events) e.id};

    for (final event in widget.events) {
      if (oldIds.contains(event.id)) continue;
      // came back before it was gone (like undo), so just show it again
      if (_leaving.remove(event.id) != null) {
        _leaveTimers.remove(event.id)?.cancel();
      } else {
        _entering.add(event.id);
      }
    }

    for (final event in oldWidget.events) {
      if (newIds.contains(event.id)) continue;
      _entering.remove(event.id);
      _leaving[event.id] = event;
      _leaveTimers[event.id]?.cancel();
      _leaveTimers[event.id] = Timer(_fadeDuration, () {
        if (!mounted) return;
        setState(() {
          _leaving.remove(event.id);
          _leaveTimers.remove(event.id);
        });
      });
    }
  }

  @override
  void dispose() {
    for (final timer in _leaveTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        return Stack(
          children: [
            for (final event in _leaving.values)
              Positioned.fromRect(
                key: ValueKey('leaving ${event.id}'),
                rect: widget.rectFor(event, size),
                child: IgnorePointer(
                  child: _FadeScale(
                    fadeOut: true,
                    child: widget.builder(event),
                  ),
                ),
              ),
            for (final event in widget.events)
              AnimatedPositioned.fromRect(
                key: ValueKey(event.id),
                rect: widget.rectFor(event, size),
                duration: _moveDuration,
                curve: Curves.easeInOutCubic,
                child: _entering.contains(event.id)
                    ? _FadeScale(child: widget.builder(event))
                    : widget.builder(event),
              ),
          ],
        );
      },
    );
  }
}

// Fades and grows the child in once, or fades and shrinks it out
class _FadeScale extends StatelessWidget {
  final Widget child;
  final bool fadeOut;

  const _FadeScale({required this.child, this.fadeOut = false});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: fadeOut ? Tween(begin: 1, end: 0) : Tween(begin: 0, end: 1),
      duration: _fadeDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
      ),
      child: child,
    );
  }
}
