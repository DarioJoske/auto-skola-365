import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/domain/entities/school_overview.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/domain/repositories/school_overview_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/domain/usecases/load_school_overview.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/cubit/school_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/cubit/school_overview_state.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/entities/instructor_overview.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/repositories/instructor_overview_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/usecases/load_instructor_overview.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructor_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructor_overview_state.dart';

SchoolOverview schoolData() => SchoolOverview(
  date: '2026-09-17',
  timeZone: 'Europe/Zagreb',
  activeCandidates: 2,
  unassignedActiveCandidates: 1,
  pendingRequests: 0,
  overdueLessons: 0,
  confirmedToday: 1,
  completedToday: 0,
  todayLessons: const [
    OverviewLesson(
      id: 'l',
      candidateId: 'c',
      candidateName: 'Ana Anić',
      instructorId: 'i',
      instructorName: 'Ivan Ivić',
      categoryCode: 'B',
      status: 'CONFIRMED',
      startAt: '2026-09-17T10:00:00+02:00',
      endAt: '2026-09-17T11:00:00+02:00',
    ),
  ],
  requests: [],
  overdue: [],
);
InstructorOverview instructorData({bool empty = false}) => InstructorOverview(
  weekStart: '2026-09-14',
  weekEnd: '2026-09-20',
  timeZone: 'Europe/Zagreb',
  instructors: empty
      ? []
      : [
          InstructorSummary(
            id: 'i',
            name: 'Ivan Ivić',
            email: 'ivan@example.com',
            active: true,
            categoryCodes: ['B'],
            confirmedLessons: 2,
            confirmedMinutes: 120,
            candidates: const [
              AssignedCandidate(
                id: 'c',
                name: 'Ana Anić',
                status: 'ENROLLED',
                categoryCode: 'B',
              ),
            ],
          ),
        ],
);

class SchoolRepositoryFake implements SchoolOverviewRepository {
  final requests = <Completer<Result<SchoolOverview>>>[];
  String? schoolId, token;
  @override
  FutureResult<SchoolOverview> load({
    required String schoolId,
    required String accessToken,
  }) {
    this.schoolId = schoolId;
    token = accessToken;
    final request = Completer<Result<SchoolOverview>>();
    requests.add(request);
    return request.future;
  }
}

class InstructorRepositoryFake implements InstructorOverviewRepository {
  final requests = <Completer<Result<InstructorOverview>>>[];
  final queries = <String>[];
  @override
  FutureResult<InstructorOverview> load({
    required String schoolId,
    required String accessToken,
    String query = '',
    bool? active,
  }) {
    queries.add(query);
    final request = Completer<Result<InstructorOverview>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  late SchoolRepositoryFake schools;
  late InstructorRepositoryFake instructors;
  SchoolOverviewCubit schoolCubit() => SchoolOverviewCubit(
    loadOverview: LoadSchoolOverview(schools),
    schoolId: 'school',
    accessToken: 'token',
  );
  InstructorOverviewCubit instructorCubit() => InstructorOverviewCubit(
    loadOverview: LoadInstructorOverview(instructors),
    schoolId: 'school',
    accessToken: 'token',
  );
  setUp(() {
    schools = SchoolRepositoryFake();
    instructors = InstructorRepositoryFake();
  });
  test('initial states have no fabricated data or error', () async {
    final school = schoolCubit();
    final instructor = instructorCubit();
    expect(school.state.data, isNull);
    expect(school.state.isLoading, false);
    expect(school.state.failure, isNull);
    expect(instructor.state.data, isNull);
    expect(instructor.state.query, '');
    await school.close();
    await instructor.close();
  });
  blocTest<SchoolOverviewCubit, SchoolOverviewState>(
    'load, preserve data on failure, retry successfully',
    build: schoolCubit,
    act: (cubit) async {
      var load = cubit.load();
      schools.requests.last.complete(success(schoolData()));
      await load;
      load = cubit.load();
      schools.requests.last.complete(
        failure(
          const Failure(
            'Poslužitelj nije dostupan.',
            statusCode: 503,
            code: 'UNAVAILABLE',
          ),
        ),
      );
      await load;
      load = cubit.load();
      schools.requests.last.complete(success(schoolData()));
      await load;
    },
    expect: () => [
      isA<SchoolOverviewState>().having((s) => s.isLoading, 'loading', true),
      isA<SchoolOverviewState>().having(
        (s) => s.data?.activeCandidates,
        'candidates',
        2,
      ),
      isA<SchoolOverviewState>()
          .having((s) => s.data, 'preserved', isNotNull)
          .having((s) => s.isLoading, 'refresh', true),
      isA<SchoolOverviewState>()
          .having((s) => s.data, 'preserved', isNotNull)
          .having((s) => s.failure?.statusCode, 'status', 503)
          .having((s) => s.failure?.code, 'code', 'UNAVAILABLE'),
      isA<SchoolOverviewState>().having((s) => s.isLoading, 'retry', true),
      isA<SchoolOverviewState>()
          .having((s) => s.failure, 'recovered', isNull)
          .having((s) => s.data, 'data', isNotNull),
    ],
    verify: (_) {
      expect(schools.schoolId, 'school');
      expect(schools.token, 'token');
    },
  );
  test(
    'newest school refresh wins and late results after close are ignored',
    () async {
      final cubit = schoolCubit();
      final old = cubit.load();
      final latest = cubit.load();
      schools.requests[1].complete(success(schoolData()));
      await latest;
      schools.requests[0].complete(failure(const Failure('Stari odgovor')));
      await old;
      expect(cubit.state.failure, isNull);
      final pending = cubit.load();
      await cubit.close();
      schools.requests.last.complete(success(schoolData()));
      await pending;
    },
  );
  blocTest<InstructorOverviewCubit, InstructorOverviewState>(
    'search rejects stale result and supports an empty success',
    build: instructorCubit,
    act: (cubit) async {
      final old = cubit.search(' Ivan ', true);
      final latest = cubit.search('Nema', null);
      instructors.requests[1].complete(success(instructorData(empty: true)));
      await latest;
      instructors.requests[0].complete(success(instructorData()));
      await old;
    },
    expect: () => [
      isA<InstructorOverviewState>().having((s) => s.query, 'query', 'Ivan'),
      isA<InstructorOverviewState>().having(
        (s) => s.isLoading,
        'loading',
        true,
      ),
      isA<InstructorOverviewState>().having((s) => s.query, 'query', 'Nema'),
      isA<InstructorOverviewState>().having(
        (s) => s.isLoading,
        'loading',
        true,
      ),
      isA<InstructorOverviewState>()
          .having((s) => s.data?.instructors, 'empty success', isEmpty)
          .having((s) => s.query, 'latest', 'Nema'),
    ],
    verify: (_) => expect(instructors.queries, ['Ivan', 'Nema']),
  );
  blocTest<InstructorOverviewCubit, InstructorOverviewState>(
    'instructor refresh failure preserves data and increments effects',
    build: instructorCubit,
    act: (cubit) async {
      var request = cubit.load();
      instructors.requests.last.complete(success(instructorData()));
      await request;
      request = cubit.load();
      instructors.requests.last.complete(
        failure(const Failure('Zabrana', statusCode: 403)),
      );
      await request;
    },
    expect: () => [
      isA<InstructorOverviewState>().having(
        (s) => s.isLoading,
        'loading',
        true,
      ),
      isA<InstructorOverviewState>().having(
        (s) => s.data?.instructors.length,
        'loaded',
        1,
      ),
      isA<InstructorOverviewState>().having(
        (s) => s.data?.instructors.length,
        'preserved',
        1,
      ),
      isA<InstructorOverviewState>()
          .having((s) => s.data?.instructors.length, 'preserved', 1)
          .having((s) => s.failure?.statusCode, 'forbidden', 403)
          .having((s) => s.errorEventId, 'effect', 1),
    ],
  );
  test('overview lists cannot be mutated by consumers', () {
    expect(() => schoolData().todayLessons.clear(), throwsUnsupportedError);
    expect(
      () => instructorData().instructors.first.candidates.clear(),
      throwsUnsupportedError,
    );
  });
}
