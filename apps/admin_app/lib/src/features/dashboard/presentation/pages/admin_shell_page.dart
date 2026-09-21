import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

final class AdminShellPage extends StatelessWidget {
  const AdminShellPage({required this.child, super.key});
  final Widget child;
  static const _paths = [
    '/',
    '/lessons',
    '/candidates',
    '/instructors',
    '/exams',
    '/fleet',
    '/finances',
    '/documents',
    '/messages',
    '/settings',
  ];
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null) return const Scaffold(body: AppLoadingState());
    final membership = user.primaryMembership;
    final path = GoRouterState.of(context).uri.path;
    final index = _paths.indexWhere(
      (route) => route != '/' && path.startsWith(route),
    );
    return AppNavigationShell(
      mode: AppNavigationMode.admin,
      identityInSidebar: true,
      title: membership?.schoolName ?? 'Autoškola 365',
      subtitle: '${user.fullName} · ${membership?.roleName ?? "Administrator"}',
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (index) => context.go(_paths[index]),
      destinations: const [
        AppDestination(
          label: 'Pregled',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        AppDestination(
          label: 'Raspored',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
        ),
        AppDestination(
          label: 'Kandidati',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
        ),
        AppDestination(
          label: 'Instruktori',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
        ),
        AppDestination(label: 'Ispiti', icon: Icons.school_outlined),
        AppDestination(
          label: 'Vozni park',
          icon: Icons.directions_car_outlined,
        ),
        AppDestination(
          label: 'Financije',
          icon: Icons.account_balance_wallet_outlined,
        ),
        AppDestination(label: 'Dokumenti', icon: Icons.folder_outlined),
        AppDestination(label: 'Poruke', icon: Icons.chat_bubble_outline),
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
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
        ),
        child: child,
      ),
    );
  }
}
