import 'package:flutter/material.dart';
import 'app_semantic_colors.dart';

/// Visual intent supplied by the caller, independent of domain status codes.
enum AppTone {
  info,
  success,
  warning,
  error,
  neutral;

  Color foreground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = AppSemanticColors.of(context);
    return switch (this) {
      info => colors.onPrimaryContainer,
      success => status.success,
      warning => status.warning,
      error => colors.error,
      neutral => colors.onSurfaceVariant,
    };
  }

  Color background(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = AppSemanticColors.of(context);
    return switch (this) {
      info => colors.primaryContainer,
      success => status.successContainer,
      warning => status.warningContainer,
      error => colors.errorContainer,
      neutral => colors.surfaceContainer,
    };
  }
}
