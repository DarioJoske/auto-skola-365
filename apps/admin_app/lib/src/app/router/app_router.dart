import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/candidates/domain/usecases/create_candidate.dart';
import '../../features/candidates/domain/usecases/list_candidates.dart';
import '../../features/candidates/domain/usecases/update_candidate.dart';
import '../../features/candidates/presentation/pages/candidates_page.dart';
import '../../features/dashboard/presentation/pages/admin_shell_page.dart';
import '../../features/dashboard/presentation/pages/overview_page.dart';
import '../../features/instructors/domain/usecases/create_instructor.dart';
import '../../features/instructors/domain/usecases/list_instructors.dart';
import '../../features/instructors/domain/usecases/update_instructor.dart';
import '../../features/instructors/presentation/pages/instructors_page.dart';
import 'go_router_refresh_stream.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required ListCandidates listCandidates,
  required CreateCandidateUseCase createCandidate,
  required UpdateCandidateUseCase updateCandidate,
  required ListInstructors listInstructors,
  required CreateInstructorUseCase createInstructor,
  required UpdateInstructorUseCase updateInstructor,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoginRoute = state.matchedLocation == '/login';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!authState.isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      if (isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AdminShellPage(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const OverviewPage()),
          GoRoute(
            path: '/candidates',
            builder: (context, state) => CandidatesPage(
              listCandidates: listCandidates,
              createCandidate: createCandidate,
              updateCandidate: updateCandidate,
            ),
          ),
          GoRoute(
            path: '/instructors',
            builder: (context, state) => InstructorsPage(
              listInstructors: listInstructors,
              createInstructor: createInstructor,
              updateInstructor: updateInstructor,
            ),
          ),
          GoRoute(
            path: '/lessons',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Voznje'),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Postavke'),
          ),
        ],
      ),
    ],
  );
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
