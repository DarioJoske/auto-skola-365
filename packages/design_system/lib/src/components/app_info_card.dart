import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

final class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    required this.title,
    required this.message,
    this.eyebrow,
    this.action,
    super.key,
  });
  final String title, message;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
        ],
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.space12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.space12),
          action!,
        ],
      ],
    ),
  );
}
