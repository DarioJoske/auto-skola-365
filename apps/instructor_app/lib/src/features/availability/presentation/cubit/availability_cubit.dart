import 'package:bloc/bloc.dart';
import '../../../../core/api/failure.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/availability.dart';
import '../../domain/usecases/manage_availability.dart';

final class AvailabilityState {
  const AvailabilityState({
    this.data,
    this.loading = false,
    this.saving = false,
    this.failure,
    this.actionError = false,
    this.saved = 0,
  });
  final Availability? data;
  final bool loading, saving, actionError;
  final Failure? failure;
  final int saved;
}

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit(
    this._manage,
    this._schoolId,
    this._token,
    this._instructorId,
  ) : super(const AvailabilityState());
  final ManageAvailability _manage;
  final String _schoolId, _token, _instructorId;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final generation = ++_generation;
    emit(
      AvailabilityState(data: state.data, loading: true, saved: state.saved),
    );
    final result = await _manage.load(_schoolId, _token, _instructorId);
    if (isClosed || generation != _generation) return;
    result.resolveWithFailure(
      onFailure: (f) => emit(
        AvailabilityState(
          data: [401, 403, 404].contains(f.statusCode) ? null : state.data,
          failure: f,
          saved: state.saved,
        ),
      ),
      onSuccess: (data) =>
          emit(AvailabilityState(data: data, saved: state.saved)),
    );
  }

  Future<void> save(Availability data) async {
    if (isClosed || state.saving || state.data == null) return;
    ++_generation;
    emit(AvailabilityState(data: state.data, saving: true, saved: state.saved));
    final result = await _manage.save(_schoolId, _token, _instructorId, data);
    if (isClosed) return;
    result.resolveWithFailure(
      onFailure: (f) => emit(
        AvailabilityState(
          data: state.data,
          failure: f,
          actionError: true,
          saved: state.saved,
        ),
      ),
      onSuccess: (data) =>
          emit(AvailabilityState(data: data, saved: state.saved + 1)),
    );
  }
}
