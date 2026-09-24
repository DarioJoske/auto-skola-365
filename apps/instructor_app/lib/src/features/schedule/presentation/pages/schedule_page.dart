import '../../domain/usecases/confirm_instructor_lesson.dart';
import '../../domain/usecases/cancel_instructor_lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/list_instructor_lessons.dart';
import '../cubit/schedule_cubit.dart';

import 'schedule_view.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final membership = authState.instructorMembership;
        final accessToken = authState.accessToken;

        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (membership == null || accessToken == null) {
          return _ScheduleAccessError(
            onLogout: () => context.read<AuthCubit>().logout(),
          );
        }

        return BlocProvider(
          create: (_) => ScheduleCubit(
            listInstructorLessons: getIt<ListInstructorLessons>(),
            confirmInstructorLesson: getIt<ConfirmInstructorLesson>(),
            cancelInstructorLesson: getIt<CancelInstructorLesson>(),
            schoolId: membership.schoolId,
            accessToken: accessToken,
          )..load(),
          child: const ScheduleView(),
        );
      },
    );
  }
}

class _ScheduleAccessError extends StatelessWidget {
  const _ScheduleAccessError({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: colorScheme.onErrorContainer),
                const SizedBox(height: 12),
                Text(
                  'Korisnik nema pristup instruktorskom rasporedu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Odjavi se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
