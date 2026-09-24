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
      final value when value.startsWith('/candidates') => 2,
      '/home' => 0,
      final value when value.startsWith('/lessons') => 0,
      '/messages' => 3,
      '/profile' || '/settings' || '/availability' => 4,
      _ => 1,
    };
    return AppNavigationShell(
      title:
          context.watch<AuthCubit>().state.instructorMembership?.schoolName ??
          'Instruktor',
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => context.go(
        ['/home', '/', '/candidates', '/messages', '/profile'][index],
      ),
      destinations: const [
        AppDestination(
          label: 'Danas',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
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
          tooltip: 'Odjava',
          onPressed: () => context.read<AuthCubit>().logout(),
          icon: const Icon(Icons.logout),
        ),
      ],
      child: child,
    );
  }
}
