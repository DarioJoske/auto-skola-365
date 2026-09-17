import 'package:flutter/material.dart';
import '../theme/app_tone.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

final class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.tone,
    this.isPositive = false,
    super.key,
  });

  final String label;
  final AppTone? tone;

  /// Legacy success selector used when [tone] is omitted.
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final intent = tone ?? (isPositive ? AppTone.success : AppTone.info);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: intent.background(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: intent.foreground(context)),
        ),
      ),
    );
  }
}
