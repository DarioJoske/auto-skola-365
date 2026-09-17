import 'app_palette.dart';

/// The 21 light-theme aliases in the Figma `365 Color` collection.
abstract final class AppColors {
  static const primary = AppPalette.blue600;
  static const onPrimary = AppPalette.white;
  static const primaryContainer = AppPalette.blue50;
  static const onPrimaryContainer = AppPalette.blue900;
  static const background = AppPalette.slate25;
  static const surface = AppPalette.white;
  static const surfaceContainer = AppPalette.slate50;
  static const onSurface = AppPalette.slate900;
  static const onSurfaceVariant = AppPalette.slate600;
  static const outline = AppPalette.slate400;
  static const outlineVariant = AppPalette.slate100;
  static const inverseSurface = AppPalette.slate900;
  static const inverseOnSurface = AppPalette.slate25;
  static const accent = AppPalette.lime300;
  static const onAccent = AppPalette.lime950;
  static const success = AppPalette.green800;
  static const successContainer = AppPalette.green50;
  static const warning = AppPalette.amber800;
  static const warningContainer = AppPalette.amber50;
  static const error = AppPalette.red700;
  static const errorContainer = AppPalette.red50;
}
