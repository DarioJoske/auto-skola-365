import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/result_extensions.dart';
import '../../domain/entities/instructor_filters.dart';
import '../../domain/entities/save_instructor.dart';
import '../../domain/usecases/create_instructor.dart';
import '../../domain/usecases/list_instructors.dart';
import '../../domain/usecases/update_instructor.dart';
import 'instructors_state.dart';

class InstructorsCubit extends Cubit<InstructorsState> {
  InstructorsCubit({
    required ListInstructors listInstructors,
    required CreateInstructorUseCase createInstructor,
    required UpdateInstructorUseCase updateInstructor,
    required String schoolId,
    required String accessToken,
  }) : _listInstructors = listInstructors,
       _createInstructor = createInstructor,
       _updateInstructor = updateInstructor,
       _schoolId = schoolId,
       _accessToken = accessToken,
       super(const InstructorsState.initial());

  final ListInstructors _listInstructors;
  final CreateInstructorUseCase _createInstructor;
  final UpdateInstructorUseCase _updateInstructor;
  final String _schoolId;
  final String _accessToken;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: InstructorsStatus.loading,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _listInstructors(
      schoolId: _schoolId,
      accessToken: _accessToken,
      filters: state.filters,
    );

    result.resolveWithFailure(
      onFailure: (failure) => emit(
        state.copyWith(
          status: InstructorsStatus.failure,
          errorMessage: failure.message,
          errorStatusCode: failure.statusCode,
          errorEventId: state.errorEventId + 1,
        ),
      ),
      onSuccess: (instructors) => emit(
        InstructorsState(
          status: InstructorsStatus.loaded,
          instructors: instructors,
          filters: state.filters,
        ),
      ),
    );
  }

  Future<void> applyFilters(InstructorFilters filters) async {
    emit(state.copyWith(filters: filters));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(filters: state.filters.clear()));
    await load();
  }

  Future<bool> create(SaveInstructor instructor) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _createInstructor(
      schoolId: _schoolId,
      accessToken: _accessToken,
      instructor: instructor,
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

  Future<bool> update(String instructorId, SaveInstructor instructor) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    final result = await _updateInstructor(
      schoolId: _schoolId,
      accessToken: _accessToken,
      instructorId: instructorId,
      instructor: instructor,
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
