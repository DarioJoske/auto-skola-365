import 'package:bloc/bloc.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/usecases/load_instructor_overview.dart';
import 'instructor_overview_state.dart';

class InstructorOverviewCubit extends Cubit<InstructorOverviewState> {
  InstructorOverviewCubit({
    required LoadInstructorOverview loadOverview,
    required String schoolId,
    required String accessToken,
  }) : _load = loadOverview,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const InstructorOverviewState());
  final LoadInstructorOverview _load;
  final String _schoolId, _accessToken;
  int _generation = 0;
  Future<void> load() async {
    final generation = ++_generation;
    emit(
      InstructorOverviewState(
        data: state.data,
        isLoading: true,
        errorEventId: state.errorEventId,
        query: state.query,
        active: state.active,
      ),
    );
    final result = await _load(
      schoolId: _schoolId,
      accessToken: _accessToken,
      query: state.query,
      active: state.active,
    );
    if (isClosed || generation != _generation) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        InstructorOverviewState(
          data: state.data,
          failure: failure,
          errorEventId: state.errorEventId + 1,
          query: state.query,
          active: state.active,
        ),
      ),
      onSuccess: (data) => emit(
        InstructorOverviewState(
          data: data,
          errorEventId: state.errorEventId,
          query: state.query,
          active: state.active,
        ),
      ),
    );
  }

  Future<void> search(String query, bool? active) async {
    emit(
      InstructorOverviewState(
        data: state.data,
        query: query.trim(),
        active: active,
        errorEventId: state.errorEventId,
      ),
    );
    await load();
  }
}
