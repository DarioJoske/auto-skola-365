import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/load_portal.dart';
import '../../domain/usecases/request_lesson.dart';
import '../cubit/portal_cubit.dart';

final class PortalShell extends StatelessWidget {
  const PortalShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      if (!auth.isAuthenticated || auth.candidateMembership == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return BlocProvider(
        key: ValueKey('${auth.user!.id}:${auth.candidateMembership!.schoolId}'),
        create: (_) => PortalCubit(
          loadPortal: getIt<LoadPortal>(),
          requestLesson: getIt<RequestLesson>(),
          schoolId: auth.candidateMembership!.schoolId,
          accessToken: auth.accessToken!,
        )..load(),
        child: BlocListener<PortalCubit, PortalState>(
          listenWhen: (previous, current) =>
              previous.errorId != current.errorId ||
              previous.savedId != current.savedId,
          listener: (context, state) {
            final failure = state.actionFailure ?? state.loadFailure;
            if (failure?.statusCode == 401) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Sesija je istekla. Prijavite se ponovno.'),
                  ),
                );
              context.read<AuthCubit>().logout();
            } else if (state.actionFailure != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.actionFailure!.message)),
              );
            }
          },
          child: _ShellLayout(path: path, child: child),
        ),
      );
    },
  );
}

final class _ShellLayout extends StatelessWidget {
  const _ShellLayout({required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final index = path == '/lessons'
        ? 1
        : path == '/profile'
        ? 2
        : 0;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    void select(int index) => context.go(['/', '/lessons', '/profile'][index]);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('Autoškola 365'),
          ],
        ),
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
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    label: Text('Pregled'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('Termini'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    label: Text('Moj profil'),
                  ),
                ],
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: 'Pregled',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Termini',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Moj profil',
                ),
              ],
            ),
    );
  }
}
