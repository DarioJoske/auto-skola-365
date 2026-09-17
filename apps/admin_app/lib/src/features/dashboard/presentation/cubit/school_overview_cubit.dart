import 'package:bloc/bloc.dart';
import '../../../../core/api/result_extensions.dart';
import '../../domain/usecases/load_school_overview.dart';
import 'school_overview_state.dart';

class SchoolOverviewCubit extends Cubit<SchoolOverviewState> {
  SchoolOverviewCubit({
    required LoadSchoolOverview loadOverview,
    required String schoolId,
    required String accessToken,
  }) : _load = loadOverview,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const SchoolOverviewState());
  final LoadSchoolOverview _load;
  final String _schoolId, _accessToken;
  int _generation = 0;
  Future<void> load() async {
    final generation = ++_generation;
    emit(
      SchoolOverviewState(
        data: state.data,
        isLoading: true,
        errorEventId: state.errorEventId,
      ),
    );
    final result = await _load(schoolId: _schoolId, accessToken: _accessToken);
    if (isClosed || generation != _generation) return;
    result.resolveWithFailure(
      onFailure: (failure) => emit(
        SchoolOverviewState(
          data: state.data,
          failure: failure,
          errorEventId: state.errorEventId + 1,
        ),
      ),
      onSuccess: (data) => emit(
        SchoolOverviewState(data: data, errorEventId: state.errorEventId),
      ),
    );
  }
}
