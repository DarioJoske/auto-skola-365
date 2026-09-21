import 'planned_routes.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/candidates/presentation/pages/instructor_candidates_page.dart';
import '../../features/schedule/presentation/pages/lesson_detail_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/instructor_shell_page.dart';
import 'go_router_refresh_stream.dart';

GoRouter createAppRouter({required AuthCubit authCubit}) {
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
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) =>
            _noTransitionPage(state, InstructorShellPage(child: child)),
        routes: [
          ...plannedRoutes(),
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const SchedulePage()),
          ),
          GoRoute(
            path: '/lessons/:lessonId',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              LessonDetailPage(lessonId: state.pathParameters['lessonId']!),
            ),
          ),
          GoRoute(
            path: '/candidates',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const InstructorCandidatesPage()),
          ),
          GoRoute(
            path: '/candidates/:id/progress',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              ProgressPage(
                resource: 'candidates',
                id: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/lessons/:id/progress',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              ProgressPage(
                resource: 'lessons',
                id: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const SettingsPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const SettingsPage()),
          ),
        ],
      ),
    ],
  );
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}
