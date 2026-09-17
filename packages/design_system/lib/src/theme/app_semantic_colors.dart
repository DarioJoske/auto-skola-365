import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Status colors not represented by Material's color scheme.
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    this.success = AppColors.success,
    this.successContainer = AppColors.successContainer,
    this.warning = AppColors.warning,
    this.warningContainer = AppColors.warningContainer,
  });

  final Color success, successContainer, warning, warningContainer;

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ??
      const AppSemanticColors();

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
  }) => AppSemanticColors(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
    );
  }
}
