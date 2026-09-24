import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class WorkPageHeader extends StatelessWidget {
  const WorkPageHeader({
    required this.title,
    this.subtitle,
    this.onRefresh,
    this.backPath,
    super.key,
  });
  final String title;
  final String? subtitle, backPath;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (backPath != null)
          IconButton(
            tooltip: 'Natrag',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(backPath!),
            icon: const Icon(Icons.arrow_back),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Osvježi',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    ),
  );
}
