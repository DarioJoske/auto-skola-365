import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../../instructors/domain/entities/instructor_filters.dart';
import '../../../instructors/domain/usecases/list_instructors.dart';
import '../../domain/entities/candidate_filters.dart';
import '../../domain/entities/create_candidate.dart';
import '../../domain/entities/update_candidate.dart';
import '../../domain/usecases/create_candidate.dart';
import '../../domain/usecases/list_candidates.dart';
import '../../domain/usecases/update_candidate.dart';
import 'candidates_state.dart';

class CandidatesCubit extends Cubit<CandidatesState> {
  CandidatesCubit({
    required ListCandidates listCandidates,
    required ListInstructors listInstructors,
    required CreateCandidateUseCase createCandidate,
    required UpdateCandidateUseCase updateCandidate,
    required String schoolId,
    required String accessToken,
  }) : _listCandidates = listCandidates,
       _listInstructors = listInstructors,
       _createCandidate = createCandidate,
       _updateCandidate = updateCandidate,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const CandidatesState.initial());

  final ListCandidates _listCandidates;
  final ListInstructors _listInstructors;
  final CreateCandidateUseCase _createCandidate;
  final UpdateCandidateUseCase _updateCandidate;
  final String _schoolId;
  final String _accessToken;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: CandidatesStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final candidatesResult = await _listCandidates(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: state.filters,
    );
    final instructorsResult = await _listInstructors(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: const InstructorFilters(active: true),
    );

    final failure =
        candidatesResult.resolveWithFailure<Failure?>(
          onFailure: (failure) => failure,
          onSuccess: (_) => null,
        ) ??
        instructorsResult.resolveWithFailure<Failure?>(
          onFailure: (failure) => failure,
          onSuccess: (_) => null,
        );

    if (failure != null) {
      emit(
        state.copyWith(
          status: CandidatesStatus.failure,
          errorMessage: failure.message,
          errorStatusCode: failure.statusCode,
          errorEventId: state.errorEventId + 1,
        ),
      );
      return;
    }

    emit(
      CandidatesState(
        status: CandidatesStatus.loaded,
        candidates: candidatesResult.resolveWithFailure(
          onFailure: (_) => const [],
          onSuccess: (candidates) => candidates,
        ),
        instructors: instructorsResult.resolveWithFailure(
          onFailure: (_) => const [],
          onSuccess: (instructors) => instructors,
        ),
        filters: state.filters,
      ),
    );
  }

  Future<void> applyFilters(CandidateFilters filters) async {
    emit(state.copyWith(filters: filters));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(filters: state.filters.clear()));
    await load();
  }

  Future<bool> create(CreateCandidate candidate) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _createCandidate(
      schoolId: _schoolId,
      accessToken: _accessToken,
      candidate: candidate,
    );

    return result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
        return false;
      },
      onSuccess: (_) async {
        await load();
        return true;
      },
    );
  }

  Future<bool> update(String candidateId, UpdateCandidate candidate) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _updateCandidate(
      schoolId: _schoolId,
      accessToken: _accessToken,
      candidateId: candidateId,
      candidate: candidate,
    );

    return result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
        return false;
      },
      onSuccess: (_) async {
        await load();
        return true;
      },
    );
  }
}
