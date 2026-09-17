import 'package:flutter/material.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

/// A read-only progress display; the caller provides the backend total and text.
final class AppProgressCard extends StatelessWidget {
  const AppProgressCard({
    required this.title,
    required this.valueLabel,
    required this.subtitle,
    required this.message,
    this.progress,
    this.progressSemanticsLabel,
    this.progressSemanticsValue,
    this.isLoading = false,
    super.key,
  }) : assert(
         progress == null || (progress >= 0 && progress < double.infinity),
       );

  final String title, valueLabel, subtitle, message;

  /// The visual ratio, clamped only for the bar; `null` omits the bar.
  final double? progress;
  final String? progressSemanticsLabel, progressSemanticsValue;

  /// Whether a refresh is in progress while the current values stay visible.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppCard(
      color: colors.inverseSurface,
      radius: AppRadius.xl,
      showBorder: false,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onInverseSurface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              valueLabel,
              style: theme.textTheme.displayLarge?.copyWith(
                color: colors.onInverseSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(subtitle),
            if (progress != null || isLoading) ...[
              const SizedBox(height: AppSpacing.space12),
              LinearProgressIndicator(
                value: isLoading ? null : progress!.clamp(0.0, 1.0),
                minHeight: AppSpacing.sm,
                borderRadius: BorderRadius.circular(AppRadius.full),
                color: colors.tertiary,
                backgroundColor: colors.onInverseSurface.withValues(alpha: .16),
                semanticsLabel: progressSemanticsLabel ?? title,
                semanticsValue: progressSemanticsValue ?? valueLabel,
              ),
            ],
            const SizedBox(height: AppSpacing.space12),
            Text(message),
          ],
        ),
      ),
    );
  }
}
