import 'package:bloc/bloc.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/candidate_progress.dart';
import '../../domain/usecases/load_progress.dart';

final class ProgressState {
  const ProgressState({
    this.data,
    this.loading = false,
    this.loadFailure,
    this.eventId = 0,
  });

  final CandidateProgress? data;
  final bool loading;
  final Failure? loadFailure;
  final int eventId;
}

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required LoadProgress loadProgress,
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) : _load = loadProgress,
       _schoolId = schoolId,
       _accessToken = accessToken,
       _resource = resource,
       _id = id,
       super(const ProgressState());

  final LoadProgress _load;
  final String _schoolId;
  final String _accessToken;
  final String _resource;
  final String _id;
  int _request = 0;

  Future<void> load() async {
    if (isClosed) return;
    final request = ++_request;
    emit(
      ProgressState(data: state.data, loading: true, eventId: state.eventId),
    );
    final result = await _load(
      schoolId: _schoolId,
      accessToken: _accessToken,
      resource: _resource,
      id: _id,
    );
    if (isClosed || request != _request) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        ProgressState(
          data: failure.statusCode == 401 || failure.statusCode == 403
              ? null
              : state.data,
          loadFailure: failure,
          eventId: state.eventId + 1,
        ),
      ),
      onSuccess: (data) =>
          emit(ProgressState(data: data, eventId: state.eventId)),
    );
  }
}
