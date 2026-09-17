import 'package:flutter/material.dart';

/// Keeps wide tables and controls usable with touch, mouse and keyboard.
final class AppHorizontalScroll extends StatefulWidget {
  const AppHorizontalScroll({
    required this.child,
    this.minWidth = 0,
    super.key,
  });
  final Widget child;
  final double minWidth;
  @override
  State<AppHorizontalScroll> createState() => _AppHorizontalScrollState();
}

final class _AppHorizontalScrollState extends State<AppHorizontalScroll> {
  final _controller = ScrollController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    scrollbarOrientation: ScrollbarOrientation.bottom,
    child: SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: widget.minWidth),
        child: widget.child,
      ),
    ),
  );
}
