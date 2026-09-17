import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.calendar_today_outlined,
    this.action,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(message),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    ),
  );
}
