import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

final class AppListItem extends StatelessWidget {
  const AppListItem({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });
  final String title, subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.space12),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
