import 'package:auto_skola_design_system/design_system.dart';
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
              showSessionExpired(context);
              context.read<AuthCubit>().logout();
            } else if (state.actionFailure != null) {
              showAppSnackBar(context, state.actionFailure!.message);
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
    return AppNavigationShell(
      title: 'Autoškola 365',
      selectedIndex: index,
      onDestinationSelected: (index) =>
          context.go(['/', '/lessons', '/profile'][index]),
      destinations: const [
        AppDestination(
          label: 'Pregled',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
        ),
        AppDestination(
          label: 'Termini',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
        ),
        AppDestination(
          label: 'Moj profil',
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
