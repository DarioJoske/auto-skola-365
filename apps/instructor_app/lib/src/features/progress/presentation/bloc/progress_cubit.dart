import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/candidate_progress.dart';
import '../../domain/usecases/load_progress.dart';
import '../../domain/usecases/save_progress.dart';

class ProgressState {
  ProgressState({
    this.data,
    Map<String, String> draft = const {},
    this.loading = false,
    this.saving = false,
    this.loadFailure,
    this.actionFailure,
    this.message,
    this.eventId = 0,
  }) : draft = Map.unmodifiable(draft);
  final CandidateProgress? data;
  final Map<String, String> draft;
  final bool loading;
  final bool saving;
  final Failure? loadFailure;
  final Failure? actionFailure;
  final String? message;
  final int eventId;
}

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required LoadProgress loadProgress,
    required SaveProgress saveProgress,
    required this.schoolId,
    required this.accessToken,
    required this.resource,
    required this.id,
  }) : _load = loadProgress,
       _save = saveProgress,
       super(ProgressState(loading: true));
  final LoadProgress _load;
  final SaveProgress _save;
  final String schoolId, accessToken, resource, id;
  int _request = 0;
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final request = ++_request;
    emit(ProgressState(loading: true, eventId: state.eventId));
    final result = await _load(
      schoolId: schoolId,
      accessToken: accessToken,
      resource: resource,
      id: id,
    );
    if (isClosed || request != _request) return;
    result.resolveWithFailure(
      onFailure: (failure) =>
          emit(ProgressState(loadFailure: failure, eventId: state.eventId + 1)),
      onSuccess: (data) => emit(
        ProgressState(
          data: data,
          draft: data.lessonAssessments,
          eventId: state.eventId,
        ),
      ),
    );
  }

  void select(String skill, String status) {
    final data = state.data;
    if (isClosed || state.saving || data == null || !data.editable) return;
    if (!data.skills.any((o) => o.code == skill) ||
        !data.statuses.any((o) => o.code == status)) {
      return;
    }
    emit(
      ProgressState(
        data: data,
        draft: {...state.draft, skill: status},
        eventId: state.eventId,
      ),
    );
  }

  Future<void> save() async {
    final data = state.data;
    if (isClosed ||
        state.saving ||
        data == null ||
        !data.editable ||
        data.lessonId == null ||
        state.draft.isEmpty) {
      return;
    }
    final draft = state.draft;
    emit(
      ProgressState(
        data: data,
        draft: draft,
        saving: true,
        eventId: state.eventId,
      ),
    );
    final result = await _save(
      schoolId: schoolId,
      accessToken: accessToken,
      lessonId: data.lessonId!,
      assessments: draft,
    );
    if (isClosed) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        ProgressState(
          data: data,
          draft: draft,
          actionFailure: failure,
          eventId: state.eventId + 1,
        ),
      ),
      onSuccess: (saved) => emit(
        ProgressState(
          data: saved,
          draft: saved.lessonAssessments,
          message: 'Napredak je spremljen.',
          eventId: state.eventId + 1,
        ),
      ),
    );
  }
}
