import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../../candidates/domain/entities/instructor_candidate.dart';
import '../../../candidates/domain/entities/instructor_candidate_filters.dart';
import '../../../candidates/domain/usecases/list_instructor_candidates.dart';
import '../../domain/entities/reserve_lesson.dart';
import '../../domain/usecases/reserve_instructor_lesson.dart';

final class ReservationState {
  ReservationState({
    List<InstructorCandidate> candidates = const [],
    this.loading = false,
    this.saving = false,
    this.saved = false,
    this.loadFailure,
    this.saveFailure,
    this.eventId = 0,
  }) : candidates = List.unmodifiable(candidates);
  final List<InstructorCandidate> candidates;
  final bool loading, saving, saved;
  final Failure? loadFailure, saveFailure;
  final int eventId;
}

class ReservationCubit extends Cubit<ReservationState> {
  ReservationCubit({
    required ListInstructorCandidates listCandidates,
    required ReserveInstructorLesson reserveLesson,
    required String schoolId,
    required String accessToken,
  }) : _listCandidates = listCandidates,
       _reserveLesson = reserveLesson,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(ReservationState());
  final ListInstructorCandidates _listCandidates;
  final ReserveInstructorLesson _reserveLesson;
  final String _schoolId, _accessToken;
  int _request = 0;

  Future<void> load() async {
    if (isClosed || state.saving || state.saved) return;
    final request = ++_request;
    emit(
      ReservationState(
        candidates: state.candidates,
        loading: true,
        eventId: state.eventId,
      ),
    );
    final result = await _listCandidates(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: const InstructorCandidateFilters(),
    );
    if (isClosed || request != _request) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        ReservationState(loadFailure: failure, eventId: state.eventId + 1),
      ),
      onSuccess: (candidates) => emit(
        ReservationState(candidates: candidates, eventId: state.eventId),
      ),
    );
  }

  Future<void> reserve(ReserveLesson reservation) async {
    if (isClosed ||
        state.loading ||
        state.saving ||
        state.saved ||
        state.loadFailure != null) {
      return;
    }
    if (!state.candidates.any(
      (candidate) => candidate.id == reservation.candidateId,
    )) {
      return;
    }
    emit(
      ReservationState(
        candidates: state.candidates,
        saving: true,
        eventId: state.eventId,
      ),
    );
    final result = await _reserveLesson(
      schoolId: _schoolId,
      accessToken: _accessToken,
      reservation: reservation,
    );
    if (isClosed) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        ReservationState(
          candidates: state.candidates,
          saveFailure: failure,
          eventId: state.eventId + 1,
        ),
      ),
      onSuccess: (_) => emit(
        ReservationState(
          candidates: state.candidates,
          saved: true,
          eventId: state.eventId + 1,
        ),
      ),
    );
  }
}
