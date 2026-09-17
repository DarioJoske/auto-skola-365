import 'package:flutter/material.dart';
import '../theme/app_tone.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';
import 'app_status_badge.dart';

/// A lesson summary with preformatted data and no scheduling rules.
final class AppLessonCard extends StatelessWidget {
  const AppLessonCard({
    required this.timeLabel,
    required this.title,
    required this.details,
    required this.statusLabel,
    this.statusTone = AppTone.info,
    this.location,
    this.action,
    this.onTap,
    super.key,
  });

  final String timeLabel, title, details, statusLabel;
  final AppTone statusTone;
  final String? location;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            details,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppStatusBadge(label: statusLabel, tone: statusTone),
          if (location != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              location!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
