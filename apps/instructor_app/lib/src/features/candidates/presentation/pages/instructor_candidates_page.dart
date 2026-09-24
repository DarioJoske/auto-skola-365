import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/usecases/list_instructor_candidates.dart';
import '../cubit/instructor_candidates_cubit.dart';
import 'instructor_candidates_view.dart';

class InstructorCandidatesPage extends StatelessWidget {
  const InstructorCandidatesPage({super.key});

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
          return _CandidatesAccessError(
            onLogout: () => context.read<AuthCubit>().logout(),
          );
        }

        return BlocProvider(
          create: (_) => InstructorCandidatesCubit(
            listInstructorCandidates: getIt<ListInstructorCandidates>(),
            schoolId: membership.schoolId,
            accessToken: accessToken,
          )..load(),
          child: const InstructorCandidatesView(),
        );
      },
    );
  }
}

class _CandidatesAccessError extends StatelessWidget {
  const _CandidatesAccessError({required this.onLogout});

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
                  'Korisnik nema pristup dodijeljenim kandidatima.',
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
