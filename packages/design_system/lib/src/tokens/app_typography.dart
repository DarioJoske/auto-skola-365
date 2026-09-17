import 'package:flutter/material.dart';

/// The nine Figma text styles using the bundled regular and bold Roboto fonts.
abstract final class AppTypography {
  static const _regular = TextStyle(
    fontFamily: 'SchoolSans',
    package: 'auto_skola_design_system',
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static final display = _regular.copyWith(
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w700,
  );
  static final headline = _regular.copyWith(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
  );
  static final heading = _regular.copyWith(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );
  static final title = _regular.copyWith(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
  );
  static final titleSmall = _regular.copyWith(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
  );
  static final body = _regular.copyWith(fontSize: 16, height: 24 / 16);
  static final bodySmall = _regular.copyWith(fontSize: 14, height: 20 / 14);
  static final label = _regular.copyWith(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
  );
  static final caption = _regular.copyWith(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: headline,
    headlineLarge: headline,
    headlineMedium: heading,
    headlineSmall: heading,
    titleLarge: title,
    titleMedium: titleSmall,
    titleSmall: titleSmall,
    bodyLarge: body,
    bodyMedium: bodySmall,
    bodySmall: bodySmall,
    labelLarge: label,
    labelMedium: label,
    labelSmall: caption,
  );
}
