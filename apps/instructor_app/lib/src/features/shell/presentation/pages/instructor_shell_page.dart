import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

final class InstructorShellPage extends StatelessWidget {
  const InstructorShellPage({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = switch (location) {
      final value when value.startsWith('/candidates') => 1,
      final value when value.startsWith('/settings') => 2,
      _ => 0,
    };
    return AppNavigationShell(
      title:
          context.watch<AuthCubit>().state.instructorMembership?.schoolName ??
          'Instruktor',
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          context.go(['/', '/candidates', '/settings'][index]),
      destinations: const [
        AppDestination(
          label: 'Raspored',
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
        ),
        AppDestination(
          label: 'Kandidati',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
        ),
        AppDestination(
          label: 'Postavke',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Odjava',
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
      child: child,
    );
  }
}
