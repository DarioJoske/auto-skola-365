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
import '../../features/lessons/domain/usecases/cancel_lesson.dart';
import '../../features/lessons/domain/usecases/confirm_lesson.dart';
import '../../features/lessons/domain/usecases/create_lesson.dart';
import '../../features/lessons/domain/usecases/list_lessons.dart';
import '../../features/lessons/domain/usecases/update_lesson.dart';
import '../../features/lessons/presentation/pages/lessons_page.dart';
import 'go_router_refresh_stream.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required ListCandidates listCandidates,
  required CreateCandidateUseCase createCandidate,
  required UpdateCandidateUseCase updateCandidate,
  required ListInstructors listInstructors,
  required CreateInstructorUseCase createInstructor,
  required UpdateInstructorUseCase updateInstructor,
  required ListLessons listLessons,
  required CreateLessonUseCase createLesson,
  required UpdateLessonUseCase updateLesson,
  required ConfirmLessonUseCase confirmLesson,
  required CancelLessonUseCase cancelLesson,
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
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginPage()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) =>
            _noTransitionPage(state, AdminShellPage(child: child)),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const OverviewPage()),
          ),
          GoRoute(
            path: '/candidates',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              CandidatesPage(
                listCandidates: listCandidates,
                listInstructors: listInstructors,
                createCandidate: createCandidate,
                updateCandidate: updateCandidate,
              ),
            ),
          ),
          GoRoute(
            path: '/instructors',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              InstructorsPage(
                listInstructors: listInstructors,
                createInstructor: createInstructor,
                updateInstructor: updateInstructor,
              ),
            ),
          ),
          GoRoute(
            path: '/lessons',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              LessonsPage(
                listLessons: listLessons,
                createLesson: createLesson,
                updateLesson: updateLesson,
                confirmLesson: confirmLesson,
                cancelLesson: cancelLesson,
                listCandidates: listCandidates,
                listInstructors: listInstructors,
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const _PlaceholderPage(title: 'Postavke'),
            ),
          ),
        ],
      ),
    ],
  );
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
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
