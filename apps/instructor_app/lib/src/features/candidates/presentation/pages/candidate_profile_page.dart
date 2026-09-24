import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/app_dependencies.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../progress/domain/usecases/load_progress.dart';
import '../../../progress/presentation/bloc/progress_cubit.dart';
import '../../../schedule/domain/usecases/load_candidate_lessons.dart';
import '../../domain/usecases/get_instructor_candidate.dart';
import '../cubit/candidate_profile_cubit.dart';
import 'candidate_profile_view.dart';

final class CandidateProfilePage extends StatelessWidget {
  const CandidateProfilePage({required this.candidateId, super.key});
  final String candidateId;
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, auth) {
      final membership = auth.instructorMembership;
      final token = auth.accessToken;
      if (membership == null || token == null) {
        return const Center(child: Text('Prijavite se za pristup kandidatu.'));
      }
      return MultiBlocProvider(
        key: ValueKey('${membership.schoolId}:$token:$candidateId'),
        providers: [
          BlocProvider(
            create: (_) => CandidateProfileCubit(
              getCandidate: getIt<GetInstructorCandidate>(),
              loadLessons: getIt<LoadCandidateLessons>(),
              schoolId: membership.schoolId,
              accessToken: token,
              candidateId: candidateId,
            )..load(),
          ),
          BlocProvider(
            create: (_) => ProgressCubit(
              loadProgress: getIt<LoadProgress>(),
              schoolId: membership.schoolId,
              accessToken: token,
              resource: 'candidates',
              id: candidateId,
            )..load(),
          ),
        ],
        child: const CandidateProfileView(),
      );
    },
  );
}
