import 'package:flutter/material.dart';
import '../theme/app_tone.dart';
import '../tokens/app_spacing.dart';
import 'app_card.dart';

/// An inline message that can accompany existing content during a failure.
final class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.title,
    required this.message,
    this.tone = AppTone.info,
    this.action,
    super.key,
  });
  final String title, message;
  final AppTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AppCard(
      color: tone.background(context),
      showBorder: false,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: tone.foreground(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: tone.foreground(context)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}
