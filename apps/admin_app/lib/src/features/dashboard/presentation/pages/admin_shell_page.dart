import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';

class AdminShellPage extends StatelessWidget {
  const AdminShellPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;
    final membership = user?.primaryMembership;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 980,
            selectedIndex: _selectedIndex(context),
            onDestinationSelected: (index) => context.go(_pathForIndex(index)),
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Icon(
                Icons.directions_car_filled,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Pregled'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Kandidati'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge),
                label: Text('Instruktori'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: Text('Voznje'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Postavke'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  schoolName: membership?.schoolName ?? 'Nema skole',
                  userName: user.fullName,
                  roleName: membership?.roleName ?? 'Nema role',
                  onLogout: () => context.read<AuthCubit>().logout(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/candidates')) {
      return 1;
    }
    if (location.startsWith('/instructors')) {
      return 2;
    }
    if (location.startsWith('/lessons')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  String _pathForIndex(int index) {
    return switch (index) {
      0 => '/',
      1 => '/candidates',
      2 => '/instructors',
      3 => '/lessons',
      4 => '/settings',
      _ => '/',
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.schoolName,
    required this.userName,
    required this.roleName,
    required this.onLogout,
  });

  final String schoolName;
  final String userName;
  final String roleName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schoolName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$userName · $roleName',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Odjava',
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
