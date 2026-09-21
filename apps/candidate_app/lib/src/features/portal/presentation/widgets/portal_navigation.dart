import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/portal_cubit.dart';

final class PortalNavigation extends StatelessWidget {
  const PortalNavigation({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final index = switch (path) {
      final value when value.startsWith('/lessons') => 1,
      '/journey' || '/exams' => 2,
      '/messages' => 3,
      '/profile' || '/documents-payments' => 4,
      _ => 0,
    };
    return AppNavigationShell(
      title: 'Autoškola 365',
      selectedIndex: index,
      onDestinationSelected: (index) => context.go(
        ['/', '/lessons', '/journey', '/messages', '/profile'][index],
      ),
      destinations: const [
        AppDestination(
          label: 'Početna',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        AppDestination(
          label: 'Termini',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
        ),
        AppDestination(
          label: 'Moj put',
          icon: Icons.route_outlined,
          selectedIcon: Icons.route,
        ),
        AppDestination(
          label: 'Poruke',
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
        ),
        AppDestination(
          label: 'Profil',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Osvježi',
          onPressed: () => context.read<PortalCubit>().load(),
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Odjavi se',
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
      child: child,
    );
  }
}
