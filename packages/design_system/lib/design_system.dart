library;

import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
  static const double contentWidth = 1120;
}

abstract final class DrivingSchoolTheme {
  static const primary = Color(0xFF245EDB);
  static const background = Color(0xFFF5F7FC);
  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'SchoolSans',
      package: 'auto_skola_design_system',
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4E9F2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7DFEC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colors.primaryContainer,
        height: 76,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E9F2),
        thickness: 1,
      ),
    );
  }
}

final class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

final class AppPage extends StatelessWidget {
  const AppPage({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.contentWidth),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600
              ? AppSpacing.md
              : AppSpacing.xl,
        ),
        child: child,
      ),
    ),
  );
}

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(message),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    ),
  );
}

final class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.isPositive = false,
    super.key,
  });
  final String label;
  final bool isPositive;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: isPositive ? const Color(0xFFE4F3EC) : const Color(0xFFECF1FC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isPositive ? const Color(0xFF17613F) : const Color(0xFF244B94),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
