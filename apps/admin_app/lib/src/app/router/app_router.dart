import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/candidates/domain/entities/candidate_filters.dart';
import '../../features/candidates/domain/usecases/create_candidate.dart';
import '../../features/candidates/domain/usecases/list_candidates.dart';
import '../../features/candidates/domain/usecases/update_candidate.dart';
import '../../features/candidates/presentation/pages/candidates_page.dart';
import '../../features/dashboard/domain/usecases/load_school_overview.dart';
import '../../features/dashboard/presentation/pages/admin_shell_page.dart';
import '../../features/dashboard/presentation/pages/overview_page.dart';
import '../../features/dashboard/presentation/pages/settings_placeholder_page.dart';
import '../../features/instructors/domain/usecases/create_instructor.dart';
import '../../features/instructors/domain/usecases/list_instructors.dart';
import '../../features/instructors/domain/usecases/load_instructor_overview.dart';
import '../../features/instructors/domain/usecases/update_instructor.dart';
import '../../features/instructors/presentation/pages/instructor_overview_page.dart';
import '../../features/instructors/presentation/pages/instructors_page.dart';
import '../../features/lessons/domain/entities/lesson_filters.dart';
import '../../features/lessons/domain/usecases/cancel_lesson.dart';
import '../../features/lessons/domain/usecases/confirm_lesson.dart';
import '../../features/lessons/domain/usecases/create_lesson.dart';
import '../../features/lessons/domain/usecases/list_lessons.dart';
import '../../features/lessons/domain/usecases/update_lesson.dart';
import '../../features/lessons/presentation/pages/lessons_page.dart';
import 'go_router_refresh_stream.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required LoadSchoolOverview loadSchoolOverview,
  required LoadInstructorOverview loadInstructorOverview,
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
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              OverviewPage(loadOverview: loadSchoolOverview),
            ),
          ),
          GoRoute(
            path: '/candidates',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              CandidatesPage(
                key: ValueKey(state.uri.toString()),
                initialFilters: CandidateFilters(
                  query: state.uri.queryParameters['query'],
                  assignedInstructorId:
                      state.uri.queryParameters['instructorId'],
                  withoutInstructor:
                      state.uri.queryParameters['withoutInstructor'] == 'true',
                ),
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
              InstructorOverviewPage(
                loadOverview: loadInstructorOverview,
                query: state.uri.queryParameters['query'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/instructors/manage',
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
                key: ValueKey(state.uri.toString()),
                initialFilters: _lessonFilters(state.uri),
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
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const SettingsPlaceholderPage()),
          ),
        ],
      ),
    ],
  );
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}

LessonFilters? _lessonFilters(Uri uri) {
  if (uri.queryParameters.isEmpty) return null;
  final date =
      DateTime.tryParse(uri.queryParameters['date'] ?? '')?.toLocal() ??
      DateTime.now();
  final start = DateTime(date.year, date.month, date.day);
  return LessonFilters(
    from: start,
    to: start.add(const Duration(days: 7)),
    instructorId: uri.queryParameters['instructorId'],
    candidateId: uri.queryParameters['candidateId'],
    status:
        const [
          'REQUESTED',
          'CONFIRMED',
          'CANCELLED',
        ].contains(uri.queryParameters['status'])
        ? uri.queryParameters['status']
        : null,
  );
}
