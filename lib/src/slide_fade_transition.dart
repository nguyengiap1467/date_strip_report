// SlideFadeTransition is copied from calendar_strip
// (https://github.com/IronLad85/flutter_calendar_strip)
// Copyright (c) 2019, Siddharth V Sakre. Licensed under the BSD 3-Clause
// License. See THIRD_PARTY_NOTICES.md for the full license text.
//
// Changes: const constructor with key, the delayed start is cancelled on
// dispose (it used to call forward() on a disposed controller), and the
// controller is disposed before super.dispose().

// The state class refers to its own deprecated widget.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';

/// Fades and slides [child] up into place, optionally after [delay]
/// milliseconds. Changing [id] replays the animation.
///
/// Not used by `DateStripReport`. Kept for compatibility with 1.x.
@Deprecated(
  'Not used by DateStripReport. Combine FadeTransition and SlideTransition '
  'instead. Will be removed in 3.0.0.',
)
class SlideFadeTransition extends StatefulWidget {
  /// Creates the transition.
  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.id,
    this.delay,
    this.curve,
  });

  /// The widget to animate.
  final Widget child;

  /// Delay before the animation starts, in milliseconds.
  final int? delay;

  /// Changing this value replays the animation.
  final String id;

  /// Curve of the slide. Defaults to [Curves.decelerate].
  final Curve? curve;

  @override
  SlideFadeTransitionState createState() => SlideFadeTransitionState();
}

/// State of a [SlideFadeTransition].
@Deprecated('Will be removed in 3.0.0 together with SlideFadeTransition.')
class SlideFadeTransitionState extends State<SlideFadeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late Animation<Offset> _offset;
  Timer? _delayedStart;

  @override
  void initState() {
    super.initState();
    _offset = _buildOffset();
    final delay = widget.delay;
    if (delay == null) {
      _controller.forward();
    } else {
      _forwardAfter(delay);
    }
  }

  @override
  void didUpdateWidget(SlideFadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.curve != oldWidget.curve) _offset = _buildOffset();
    if (widget.id != oldWidget.id) {
      _controller.reset();
      _forwardAfter(widget.delay ?? 1);
    }
  }

  Animation<Offset> _buildOffset() =>
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          curve: widget.curve ?? Curves.decelerate,
          parent: _controller,
        ),
      );

  void _forwardAfter(int milliseconds) {
    _delayedStart?.cancel();
    _delayedStart = Timer(Duration(milliseconds: milliseconds), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayedStart?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _controller,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}
