import 'package:flutter/material.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

final class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.elevation = AppElevation.none,
    this.color,
    this.radius = AppRadius.lg,
    this.showBorder = true,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppElevation elevation;
  final Color? color;
  final double radius;
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: showBorder
          ? BorderSide(color: Theme.of(context).colorScheme.outlineVariant)
          : BorderSide.none,
    );
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevation.shadows,
      ),
      child: Card(
        color: color,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, customBorder: shape, child: content),
      ),
    );
  }
}
