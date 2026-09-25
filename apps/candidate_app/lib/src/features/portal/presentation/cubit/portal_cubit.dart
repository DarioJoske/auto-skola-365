import '../../domain/usecases/respond_proposal.dart';
import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import 'portal_state.dart';
import '../../domain/usecases/load_portal.dart';
import '../../domain/usecases/request_lesson.dart';

class PortalCubit extends Cubit<PortalState> {
  PortalCubit({
    required RespondProposal respondProposal,
    required LoadPortal loadPortal,
    required RequestLesson requestLesson,
    required String schoolId,
    required String accessToken,
  }) : _respond = respondProposal,
       _load = loadPortal,
       _request = requestLesson,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const PortalState());
  final RespondProposal _respond;
  final LoadPortal _load;
  final RequestLesson _request;
  final String _schoolId, _accessToken;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final generation = ++_generation;
    emit(
      PortalState(
        lastRequestedStart: state.lastRequestedStart,
        responseId: state.responseId,
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
          lastRequestedStart: state.lastRequestedStart,
          responseId: state.responseId,
          data: failure.statusCode == 401 || failure.statusCode == 403
              ? null
              : state.data,
          loadFailure: failure,
          errorId: state.errorId + 1,
          savedId: state.savedId,
        ),
      ),
      onSuccess: (data) => emit(
        PortalState(
          lastRequestedStart: state.lastRequestedStart,
          responseId: state.responseId,
          data: data,
          errorId: state.errorId,
          savedId: state.savedId,
        ),
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
          lastRequestedStart: state.lastRequestedStart,
          responseId: state.responseId,
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
        lastRequestedStart: state.lastRequestedStart,
        responseId: state.responseId,
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
          lastRequestedStart: state.lastRequestedStart,
          responseId: state.responseId,
          data: state.data,
          actionFailure: failure,
          errorId: state.errorId + 1,
          savedId: state.savedId,
        ),
      ),
      onSuccess: (_) async {
        emit(
          PortalState(
            lastRequestedStart: startAt,
            responseId: state.responseId,
            data: state.data,
            errorId: state.errorId,
            savedId: state.savedId + 1,
          ),
        );
        await load();
      },
    );
  }

  Future<void> respondProposal(
    String lessonId,
    DateTime startAt,
    bool accept,
  ) async {
    if (isClosed || state.saving) return;
    ++_generation;
    emit(
      PortalState(
        data: state.data,
        saving: true,
        errorId: state.errorId,
        savedId: state.savedId,
        lastRequestedStart: state.lastRequestedStart,
        responseId: state.responseId,
      ),
    );
    final result = await _respond(
      schoolId: _schoolId,
      accessToken: _accessToken,
      lessonId: lessonId,
      startAt: startAt,
      accept: accept,
    );
    if (isClosed) return;
    await result.resolveWithFailure<Future<void>>(
      onFailure: (f) async => emit(
        PortalState(
          data: state.data,
          actionFailure: f,
          errorId: state.errorId + 1,
          savedId: state.savedId,
          lastRequestedStart: state.lastRequestedStart,
          responseId: state.responseId,
        ),
      ),
      onSuccess: (_) async {
        emit(
          PortalState(
            data: state.data,
            errorId: state.errorId,
            savedId: state.savedId,
            lastRequestedStart: state.lastRequestedStart,
            responseId: state.responseId + 1,
          ),
        );
        await load();
      },
    );
  }
}
