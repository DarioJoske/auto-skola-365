import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/candidate_portal.dart';
import '../../domain/usecases/load_portal.dart';
import '../../domain/usecases/request_lesson.dart';

final class PortalState {
  const PortalState({
    this.data,
    this.loading = false,
    this.saving = false,
    this.loadFailure,
    this.actionFailure,
    this.errorId = 0,
    this.savedId = 0,
  });
  final CandidatePortal? data;
  final bool loading, saving;
  final Failure? loadFailure, actionFailure;
  final int errorId, savedId;
}

class PortalCubit extends Cubit<PortalState> {
  PortalCubit({
    required LoadPortal loadPortal,
    required RequestLesson requestLesson,
    required String schoolId,
    required String accessToken,
  }) : _load = loadPortal,
       _request = requestLesson,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const PortalState());
  final LoadPortal _load;
  final RequestLesson _request;
  final String _schoolId, _accessToken;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final generation = ++_generation;
    emit(
      PortalState(
        data: state.data,
        loading: true,
        errorId: state.errorId,
        savedId: state.savedId,
      ),
    );
    final result = await _load(schoolId: _schoolId, accessToken: _accessToken);
    if (isClosed || generation != _generation) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        PortalState(
          data: failure.statusCode == 401 || failure.statusCode == 403
              ? null
              : state.data,
          loadFailure: failure,
          errorId: state.errorId + 1,
          savedId: state.savedId,
        ),
      ),
      onSuccess: (data) => emit(
        PortalState(data: data, errorId: state.errorId, savedId: state.savedId),
      ),
    );
  }

  Future<void> requestLesson(DateTime startAt, String? notes) async {
    if (isClosed || state.saving || state.data?.canRequestLesson != true) {
      return;
    }
    if (!startAt.isAfter(DateTime.now())) {
      emit(
        PortalState(
          data: state.data,
          actionFailure: const Failure('Termin mora biti u budućnosti.'),
          errorId: state.errorId + 1,
          savedId: state.savedId,
        ),
      );
      return;
    }
    ++_generation;
    emit(
      PortalState(
        data: state.data,
        saving: true,
        errorId: state.errorId,
        savedId: state.savedId,
      ),
    );
    final result = await _request(
      schoolId: _schoolId,
      accessToken: _accessToken,
      startAt: startAt,
      notes: notes,
    );
    if (isClosed) return;
    await result.resolveWithFailure<Future<void>>(
      onFailure: (failure) async => emit(
        PortalState(
          data: state.data,
          actionFailure: failure,
          errorId: state.errorId + 1,
          savedId: state.savedId,
        ),
      ),
      onSuccess: (_) async {
        emit(
          PortalState(
            data: state.data,
            errorId: state.errorId,
            savedId: state.savedId + 1,
          ),
        );
        await load();
      },
    );
  }
}
