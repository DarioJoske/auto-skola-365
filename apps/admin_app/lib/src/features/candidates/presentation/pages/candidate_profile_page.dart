import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../lessons/domain/usecases/list_lessons.dart';
import '../../domain/usecases/load_candidate.dart';
import '../cubit/candidate_profile_cubit.dart';
import 'candidate_profile_view.dart';

final class CandidateProfilePage extends StatelessWidget {
  const CandidateProfilePage({
    required this.candidateId,
    required this.loadCandidate,
    required this.listLessons,
    super.key,
  });
  final String candidateId;
  final LoadCandidate loadCandidate;
  final ListLessons listLessons;
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    return BlocProvider(
      create: (_) => CandidateProfileCubit(
        loadCandidate: loadCandidate,
        listLessons: listLessons,
        schoolId: auth.user!.primaryMembership!.schoolId,
        accessToken: auth.accessToken!,
        candidateId: candidateId,
      )..load(),
      child: const CandidateProfileView(),
    );
  }
}
