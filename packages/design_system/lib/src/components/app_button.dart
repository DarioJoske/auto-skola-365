import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

enum AppButtonVariant { filled, tonal, outlined, text }

/// A Material button with caller-owned loading state and localized labels.
final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final String? loadingLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;
    final colors = Theme.of(context).colorScheme;
    final loadingForeground = variant == AppButtonVariant.filled
        ? colors.onPrimary
        : colors.primary;
    final loadingStyle = isLoading
        ? ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(loadingForeground),
            backgroundColor: WidgetStatePropertyAll(switch (variant) {
              AppButtonVariant.filled => colors.primary,
              AppButtonVariant.tonal => colors.primaryContainer,
              AppButtonVariant.outlined => colors.surface,
              AppButtonVariant.text => Colors.transparent,
            }),
          )
        : null;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            isLoading ? loadingLabel ?? label : label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        style: loadingStyle,
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        child: content,
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        style: loadingStyle,
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        style: loadingStyle,
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        style: loadingStyle,
        onPressed: action,
        focusNode: focusNode,
        autofocus: autofocus,
        child: content,
      ),
    };
    return Semantics(liveRegion: isLoading, child: button);
  }
}
