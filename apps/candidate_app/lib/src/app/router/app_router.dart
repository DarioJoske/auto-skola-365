import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/portal/presentation/pages/portal_shell.dart';
import '../../features/portal/presentation/pages/home_page.dart';
import '../../features/portal/presentation/pages/lessons_page.dart';
import '../../features/portal/presentation/pages/profile_page.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required Listenable refresh,
}) => GoRouter(
  refreshListenable: refresh,
  redirect: (context, state) {
    if (authCubit.state.status == AuthStatus.initial ||
        authCubit.state.status == AuthStatus.loading) {
      return null;
    }
    final login = state.uri.path == '/login';
    if (!authCubit.state.isAuthenticated) return login ? null : '/login';
    return login ? '/' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, state) => const LoginPage()),
    ShellRoute(
      builder: (_, state, child) =>
          PortalShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/lessons',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const LessonsPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (_, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);
