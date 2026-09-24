import 'dart:convert';
import 'dart:typed_data';
import 'package:auto_skola_365_instructor_app/src/features/auth/domain/entities/current_user.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/domain/entities/membership.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';

const membership = Membership(
  id: 'membership',
  schoolId: 'school',
  schoolName: 'Autoškola 365',
  membershipStatus: 'ACTIVE',
  roleKey: 'instructor',
  roleName: 'Instruktor',
  roleScope: 'SCHOOL',
  permissions: ['lessons.view_assigned'],
);

class WorkflowAuth extends Cubit<AuthState> implements AuthCubit {
  WorkflowAuth()
    : super(
        const AuthState.authenticated(
          user: CurrentUser(
            id: 'user',
            email: 'marko@example.test',
            firstName: 'Marko',
            lastName: 'Babić',
            phone: null,
            status: 'ACTIVE',
            memberships: [membership],
          ),
          instructorMembership: membership,
          accessToken: 'token',
        ),
      );
  int logouts = 0;
  @override
  Future<void> logout() async {
    logouts++;
    emit(const AuthState.unauthenticated());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class WorkflowAdapter implements HttpClientAdapter {
  int completions = 0;
  int completionStatus = 200;
  int progressStatus = 200;
  String status = 'CONFIRMED';
  String? note;
  DateTime start = DateTime.now().subtract(const Duration(hours: 2));
  final paths = <String>[];
  Map<String, dynamic> get lesson => {
    'id': 'lesson',
    'schoolId': 'school',
    'candidateId': 'candidate',
    'candidateName': 'Ana Horvat',
    'instructorId': 'instructor',
    'instructorName': 'Marko Babić',
    'categoryCode': 'B',
    'categoryName': 'B',
    'branchId': null,
    'branchName': null,
    'lessonType': 'DRIVING',
    'status': status,
    'startAt': start.toUtc().toIso8601String(),
    'endAt': start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
    'confirmedAt': null,
    'cancelledAt': null,
    'notes': 'Nastaviti vježbati provjeru mrtvog kuta.',
    'createdByRole': 'INSTRUCTOR',
    'completionNote': note,
    'completedAt': status == 'COMPLETED'
        ? DateTime.now().toUtc().toIso8601String()
        : null,
  };
  Map<String, dynamic> get candidate => {
    'id': 'candidate',
    'schoolId': 'school',
    'firstName': 'Ana',
    'lastName': 'Horvat',
    'email': 'ana@example.test',
    'phone': '091 123 4567',
    'oib': null,
    'status': 'IN_DRIVING',
    'categoryCode': 'B',
    'categoryName': 'B',
    'assignedInstructorId': 'instructor',
    'assignedInstructorName': 'Marko Babić',
    'notes': null,
    'completedDrivingHours': status == 'COMPLETED' ? 26 : 25,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.method} ${options.path}');
    if (options.headers['Authorization'] != 'Bearer token') {
      return response({
        'status': 401,
        'code': 'UNAUTHORIZED',
        'message': 'Prijava je potrebna.',
        'path': options.path,
      }, 401);
    }
    final path = options.path;
    if (path.endsWith('/complete')) {
      completions++;
      if (completionStatus != 200) {
        return response({
          'status': completionStatus,
          'code': 'CONFLICT',
          'message': 'Termin nije moguće zaključiti.',
          'path': path,
        }, completionStatus);
      }
      if (status == 'COMPLETED') {
        return response({
          'status': 409,
          'code': 'CONFLICT',
          'message': 'Sat je već zaključen.',
          'path': path,
        }, 409);
      }
      note = (options.data as Map)['note'] as String?;
      status = 'COMPLETED';
      return response(lesson);
    }
    if (path.endsWith('/progress')) {
      if (progressStatus != 200) {
        return response({
          'status': progressStatus,
          'code': 'UNAVAILABLE',
          'message': 'Sate nije moguće učitati.',
          'path': path,
        }, progressStatus);
      }
      return response({
        'candidateId': 'candidate',
        'candidateName': 'Ana Horvat',
        'categoryCode': 'B',
        'completedDrivingHours': status == 'COMPLETED' ? 26 : 25,
        'requiredDrivingHours': 35,
      });
    }
    if (path.endsWith('/lessons/instructor/candidates/candidate')) {
      return response([lesson]);
    }
    if (path.endsWith('/lessons/instructor/lesson')) return response(lesson);
    if (path.endsWith('/lessons/instructor')) return response([lesson]);
    if (path.endsWith('/candidates/instructor/candidate')) {
      return response(candidate);
    }
    if (path.endsWith('/candidates/instructor')) return response([candidate]);
    throw StateError('Unexpected request: ${options.method} $path');
  }

  ResponseBody response(Object data, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
  @override
  void close({bool force = false}) {}
}
