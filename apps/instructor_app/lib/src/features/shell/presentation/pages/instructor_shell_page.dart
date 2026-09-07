import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class InstructorShellPage extends StatelessWidget {
  const InstructorShellPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = location.startsWith('/settings') ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return Text(state.instructorMembership?.schoolName ?? 'Instruktor');
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Odjava',
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(index == 0 ? '/' : '/settings');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Raspored',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Postavke',
          ),
        ],
      ),
    );
  }
}
