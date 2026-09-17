import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// Constrains content without taking ownership of scrolling.
final class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    this.maxWidth = AppSpacing.contentWidth,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.all(
                constraints.maxWidth < AppSpacing.compactBreakpoint
                    ? AppSpacing.md
                    : AppSpacing.xl,
              ),
          child: child,
        ),
      ),
    ),
  );
}
