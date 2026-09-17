import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_admin_app/src/core/api/api_client.dart';
import 'package:auto_skola_365_admin_app/src/core/api/api_exception.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/data/datasources/school_overview_remote_data_source.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/data/repositories/school_overview_repository_impl.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/data/datasources/instructor_overview_remote_data_source.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/data/repositories/instructor_overview_repository_impl.dart';

class OverviewApiFake extends Fake implements ApiClient {
  Object? error;
  dynamic response;
  String? path, token;
  Map<String, dynamic>? query;
  @override
  Future<dynamic> getJson(
    String path, {
    String? accessToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    this.path = path;
    token = accessToken;
    query = queryParameters;
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  test(
    'school DTO maps real counts and preserves school-local display offset',
    () async {
      final api = OverviewApiFake()
        ..response = {
          'date': '2026-09-17',
          'timeZone': 'Europe/Zagreb',
          'activeCandidates': 4,
          'unassignedActiveCandidates': 1,
          'pendingRequests': 2,
          'overdueLessons': 3,
          'confirmedToday': 1,
          'completedToday': 0,
          'requests': [],
          'overdue': [],
          'todayLessons': [
            {
              'id': 'l',
              'candidateId': 'c',
              'candidateName': 'Ana Anić',
              'instructorId': 'i',
              'instructorName': 'Ivan Ivić',
              'categoryCode': 'B',
              'status': 'CONFIRMED',
              'startAt': '2026-09-17T00:30:00+02:00',
              'endAt': '2026-09-17T01:30:00+02:00',
            },
          ],
        };
      final repo = SchoolOverviewRepositoryImpl(
        SchoolOverviewRemoteDataSource(api),
      );
      final result = await repo.load(schoolId: 'school', accessToken: 'token');
      result.fold((error) => fail(error.message), (data) {
        expect(data.activeCandidates, 4);
        expect(data.todayLessons.single.time, '00:30');
        expect(data.todayLessons.single.date, '2026-09-17');
      });
      expect(api.path, '/api/schools/school/overview');
      expect(api.token, 'token');
    },
  );
  test(
    'instructor DTO and search parameters preserve assigned candidates and workload',
    () async {
      final api = OverviewApiFake()
        ..response = {
          'weekStart': '2026-09-14',
          'weekEnd': '2026-09-20',
          'timeZone': 'Europe/Zagreb',
          'instructors': [
            {
              'id': 'i',
              'name': 'Ivan Ivić',
              'email': 'ivan@example.com',
              'active': true,
              'categoryCodes': ['B'],
              'confirmedLessons': 1,
              'confirmedMinutes': 60,
              'candidates': [
                {
                  'id': 'c',
                  'name': 'Ana Anić',
                  'status': 'ENROLLED',
                  'categoryCode': 'B',
                },
              ],
            },
          ],
        };
      final repo = InstructorOverviewRepositoryImpl(
        InstructorOverviewRemoteDataSource(api),
      );
      final result = await repo.load(
        schoolId: 'school',
        accessToken: 'token',
        query: 'Ivan',
        active: true,
      );
      result.fold((error) => fail(error.message), (data) {
        expect(data.instructors.single.confirmedMinutes, 60);
        expect(data.instructors.single.candidates.single.id, 'c');
      });
      expect(api.path, '/api/schools/school/instructors/overview');
      expect(api.query, {'query': 'Ivan', 'active': true});
    },
  );
  for (final status in [401, 403, 503]) {
    test('both repositories preserve structured $status failures', () async {
      final api = OverviewApiFake()
        ..error = ApiException(
          'Poruka backenda',
          statusCode: status,
          code: 'ERROR',
          path: '/api/test',
        );
      final school = await SchoolOverviewRepositoryImpl(
        SchoolOverviewRemoteDataSource(api),
      ).load(schoolId: 's', accessToken: 't');
      final instructors = await InstructorOverviewRepositoryImpl(
        InstructorOverviewRemoteDataSource(api),
      ).load(schoolId: 's', accessToken: 't');
      for (final result in [school, instructors]) {
        result.fold((failure) {
          expect(failure.statusCode, status);
          expect(failure.code, 'ERROR');
          expect(failure.path, '/api/test');
          expect(failure.message, 'Poruka backenda');
        }, (_) => fail('Expected a failure'));
      }
    });
  }
}
