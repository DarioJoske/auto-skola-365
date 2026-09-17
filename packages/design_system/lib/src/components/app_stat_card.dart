import 'package:flutter/material.dart';
import '../theme/app_tone.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

final class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    required this.detail,
    this.detailTone = AppTone.neutral,
    super.key,
  });
  final String label, value, detail;
  final AppTone detailTone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            detail,
            style: theme.textTheme.labelSmall?.copyWith(
              color: detailTone.foreground(context),
            ),
          ),
        ],
      ),
    );
  }
}
