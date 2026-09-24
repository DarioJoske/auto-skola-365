import 'package:bloc/bloc.dart';

import '../../../../core/api/result_extensions.dart';
import '../../domain/usecases/list_instructor_candidates.dart';
import 'instructor_candidates_state.dart';

class InstructorCandidatesCubit extends Cubit<InstructorCandidatesState> {
  InstructorCandidatesCubit({
    required ListInstructorCandidates listInstructorCandidates,
    required String schoolId,
    required String accessToken,
  }) : _listInstructorCandidates = listInstructorCandidates,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(InstructorCandidatesState.initial());

  final ListInstructorCandidates _listInstructorCandidates;
  final String _schoolId;
  final String _accessToken;

  int _loadRequestId = 0;

  Future<void> load() async {
    if (isClosed) return;
    final requestId = ++_loadRequestId;
    emit(
      state.copyWith(
        status: InstructorCandidatesStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _listInstructorCandidates(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: state.filters,
    );

    if (isClosed || requestId != _loadRequestId) return;

    result.resolveWithFailure(
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: InstructorCandidatesStatus.failure,
            candidates: [401, 403].contains(failure.statusCode)
                ? const []
                : state.candidates,
            errorMessage: failure.message,
            errorStatusCode: failure.statusCode,
            errorEventId: state.errorEventId + 1,
          ),
        );
      },
      onSuccess: (candidates) {
        final sorted = [...candidates]
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        emit(
          state.copyWith(
            status: InstructorCandidatesStatus.loaded,
            candidates: List.unmodifiable(sorted),
            errorMessage: null,
            errorStatusCode: null,
          ),
        );
      },
    );
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          query: normalized,
          clearQuery: normalized.isEmpty,
        ),
      ),
    );
    await load();
  }

  Future<void> filterStatus(String? status) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          status: status,
          clearStatus: status == null,
        ),
      ),
    );
    await load();
  }

  Future<void> filterCategory(String? categoryCode) async {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          categoryCode: categoryCode,
          clearCategory: categoryCode == null,
        ),
      ),
    );
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(filters: state.filters.clear()));
    await load();
  }
}
