import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/entities/candidate_filters.dart';
import '../../domain/usecases/create_candidate.dart';
import '../../domain/usecases/list_candidates.dart';
import '../../domain/usecases/update_candidate.dart';
import '../cubit/candidates_cubit.dart';

import 'candidates_view.dart';

final class CandidatesPage extends StatelessWidget {
  const CandidatesPage({
    this.initialFilters = const CandidateFilters(),
    required this.listCandidates,
    required this.listInstructors,
    required this.createCandidate,
    required this.updateCandidate,
    super.key,
  });

  final CandidateFilters initialFilters;
  final ListCandidates listCandidates;
  final ListInstructors listInstructors;
  final CreateCandidateUseCase createCandidate;
  final UpdateCandidateUseCase updateCandidate;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final membership = authState.user!.primaryMembership!;

    return BlocProvider(
      create: (_) => CandidatesCubit(
        listCandidates: listCandidates,
        listInstructors: listInstructors,
        createCandidate: createCandidate,
        updateCandidate: updateCandidate,
        schoolId: membership.schoolId,
        accessToken: authState.accessToken!,
      )..applyFilters(initialFilters),
      child: const CandidatesView(),
    );
  }
}
