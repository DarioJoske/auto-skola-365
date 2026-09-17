import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/lesson_filters.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/repositories/lessons_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_state.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/candidate_filters.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/repositories/candidates_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/entities/instructor.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/entities/instructor_filters.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/repositories/instructors_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/list_lessons.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/create_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/update_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/confirm_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/usecases/cancel_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/usecases/list_candidates.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/usecases/list_instructors.dart';

class ScheduleRepository extends Fake implements LessonsRepository {
  final filters = <LessonFilters>[];
  final requests = <Completer<Result<List<Lesson>>>>[];
  @override
  FutureResult<List<Lesson>> list({
    required String schoolId,
    required String accessToken,
    required LessonFilters filters,
  }) {
    this.filters.add(filters);
    final request = Completer<Result<List<Lesson>>>();
    requests.add(request);
    return request.future;
  }
}

class CandidatesLookup extends Fake implements CandidatesRepository {
  @override
  FutureResult<List<Candidate>> list({
    required String schoolId,
    required String accessToken,
    CandidateFilters filters = const CandidateFilters(),
  }) async => success([]);
}

class InstructorsLookup extends Fake implements InstructorsRepository {
  @override
  FutureResult<List<Instructor>> list({
    required String schoolId,
    required String accessToken,
    InstructorFilters filters = const InstructorFilters(),
  }) async => success([]);
}

void main() {
  late ScheduleRepository repository;
  final initial = LessonFilters(
    from: DateTime(2026, 9, 14),
    to: DateTime(2026, 9, 21),
    instructorId: 'instructor',
    candidateId: 'candidate',
    status: 'CONFIRMED',
  );
  LessonsCubit build() => LessonsCubit(
    listLessons: ListLessons(repository),
    createLesson: CreateLessonUseCase(repository),
    updateLesson: UpdateLessonUseCase(repository),
    confirmLesson: ConfirmLessonUseCase(repository),
    cancelLesson: CancelLessonUseCase(repository),
    listCandidates: ListCandidates(CandidatesLookup()),
    listInstructors: ListInstructors(InstructorsLookup()),
    schoolId: 'school',
    accessToken: 'token',
    initialFilters: initial,
  );
  setUp(() => repository = ScheduleRepository());
  test(
    'initial linked schedule retains date, instructor, candidate and status',
    () async {
      final cubit = build();
      expect(cubit.state.filters, same(initial));
      expect(cubit.state.status, LessonsStatus.initial);
      await cubit.close();
    },
  );
  blocTest<LessonsCubit, LessonsState>(
    'new calendar request wins and hidden candidate filter can be cleared',
    build: build,
    act: (cubit) async {
      final old = cubit.load();
      final latest = cubit.clearCandidateFilter();
      repository.requests[1].complete(success([]));
      await latest;
      repository.requests[0].complete(failure(const Failure('Old failure')));
      await old;
    },
    expect: () => [
      isA<LessonsState>().having(
        (s) => s.status,
        'loading',
        LessonsStatus.loading,
      ),
      isA<LessonsState>().having(
        (s) => s.filters.candidateId,
        'clear candidate',
        null,
      ),
      isA<LessonsState>().having(
        (s) => s.status,
        'loading',
        LessonsStatus.loading,
      ),
      isA<LessonsState>()
          .having((s) => s.status, 'latest success', LessonsStatus.loaded)
          .having((s) => s.filters.instructorId, 'instructor', 'instructor')
          .having((s) => s.errorMessage, 'no stale failure', null),
    ],
    verify: (_) {
      expect(repository.filters.first.candidateId, 'candidate');
      expect(repository.filters.last.candidateId, isNull);
    },
  );
}
