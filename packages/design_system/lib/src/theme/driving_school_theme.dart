import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_semantic_colors.dart';

abstract final class DrivingSchoolTheme {
  static const primary = AppColors.primary;
  static const background = AppColors.background;

  static ThemeData light() {
    final colors =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.primary,
          onSecondary: AppColors.onPrimary,
          secondaryContainer: AppColors.primaryContainer,
          onSecondaryContainer: AppColors.primary,
          tertiary: AppColors.accent,
          onTertiary: AppColors.onAccent,
          tertiaryContainer: AppColors.accent,
          onTertiaryContainer: AppColors.onAccent,
          surface: AppColors.surface,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.background,
          surfaceContainerHigh: AppColors.surfaceContainer,
          surfaceContainerHighest: AppColors.outlineVariant,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          inverseSurface: AppColors.inverseSurface,
          onInverseSurface: AppColors.inverseOnSurface,
          inversePrimary: AppColors.primaryContainer,
          error: AppColors.error,
          onError: AppColors.onPrimary,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          shadow: AppColors.inverseSurface,
          surfaceTint: Colors.transparent,
        );
    final text = AppTypography.textTheme.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.space12,
        ),
      ),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) &&
                !states.contains(WidgetState.disabled)
            ? BorderSide(color: colors.onPrimaryContainer, width: 3)
            : BorderSide.none,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.onSurfaceVariant
            : null,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.surfaceContainer
            : null,
      ),
      elevation: const WidgetStatePropertyAll(0),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          borderSide: BorderSide(color: color, width: width),
        );
    final inputDecoration = InputDecorationTheme(
      filled: false,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.surfaceContainer
            : colors.surface,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      isDense: true,
      labelStyle: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => text.bodyLarge!.copyWith(
          height: 4 / 3,
          color: states.contains(WidgetState.error)
              ? colors.error
              : states.contains(WidgetState.focused)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      helperStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      errorStyle: text.bodyMedium?.copyWith(color: colors.error),
      errorMaxLines: 4,
      border: border(colors.outline),
      enabledBorder: border(colors.outline),
      focusedBorder: border(colors.primary, 2),
      disabledBorder: border(colors.outlineVariant),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'SchoolSans',
      package: 'auto_skola_design_system',
      textTheme: text,
      extensions: const [AppSemanticColors()],
      scaffoldBackgroundColor: background,
      disabledColor: colors.onSurfaceVariant,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: inputDecoration,
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(2),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.bodyLarge),
          minimumSize: const WidgetStatePropertyAll(Size(112, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          visualDensity: VisualDensity.standard,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyLarge,
        inputDecorationTheme: inputDecoration,
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: colors.outlineVariant);
            }
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colors.primary, width: 3);
            }
            return BorderSide(color: colors.outline);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: button.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        height: 76,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: colors.primary,
        ),
        unselectedLabelTextStyle: text.bodyMedium,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}
