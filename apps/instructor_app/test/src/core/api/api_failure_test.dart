import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_skola_365_instructor_app/src/core/api/api_client.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/data/datasources/progress_remote_data_source.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class ErrorAdapter implements HttpClientAdapter {
  ErrorAdapter(this.status, this.body);
  final int? status;
  final Object? body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (status == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status!,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late ApiClient api;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    api = ApiClient(dio);
  });
  tearDown(() => dio.close(force: true));

  for (final status in [400, 401, 403, 404, 409, 500]) {
    for (final method in ['GET', 'POST']) {
      test(
        '$method $status preserves structured backend details in Failure',
        () async {
          dio.httpClientAdapter = ErrorAdapter(status, {
            'status': status,
            'code': 'BACKEND_$status',
            'message': 'Poruka poslužitelja za $status.',
            'path': '/resource',
          });
          final request = switch (method) {
            'GET' => api.getJson('/resource'),

            _ => api.postJson('/resource', body: {}),
          };
          try {
            await request;
            fail('The request must fail');
          } catch (error) {
            final failure = Failure.fromException(error);
            expect(failure.statusCode, status);
            expect(failure.code, 'BACKEND_$status');
            expect(failure.path, '/resource');
            expect(failure.message, 'Poruka poslužitelja za $status.');
          }
        },
      );
    }
    test('repository returns Left with the original $status details', () async {
      dio.httpClientAdapter = ErrorAdapter(status, {
        'status': status,
        'code': 'BACKEND_$status',
        'message': 'Izvorna poruka.',
        'path': '/resource',
      });
      final result = await ProgressRepositoryImpl(ProgressRemoteDataSource(api))
          .load(
            schoolId: 'school',
            accessToken: 'token',
            resource: 'candidates',
            id: 'candidate',
          );
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure.statusCode, status);
        expect(failure.code, 'BACKEND_$status');
        expect(failure.path, '/resource');
        expect(failure.message, 'Izvorna poruka.');
      }, (_) => fail('Expected Left'));
    });
  }

  for (final body in [
    null,
    '<html>Unavailable</html>',
    {'message': ' ', 'code': 12, 'path': 42},
  ]) {
    test('unavailable structured body uses a safe fallback: $body', () async {
      dio.httpClientAdapter = ErrorAdapter(401, body);
      await expectLater(
        api.getJson('/resource'),
        throwsA(
          isA<ApiFailureSource>()
              .having((e) => e.statusCode, 'status', 401)
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.path, 'path', isNull)
              .having(
                (e) => e.message,
                'message',
                'Sesija je istekla. Prijavi se ponovno.',
              ),
        ),
      );
    });
  }
  test('connection failure has no fabricated HTTP status or code', () async {
    dio.httpClientAdapter = ErrorAdapter(null, null);
    final result = await ProgressRepositoryImpl(ProgressRemoteDataSource(api))
        .load(
          schoolId: 'school',
          accessToken: 'token',
          resource: 'candidates',
          id: 'candidate',
        );
    result.fold((failure) {
      expect(failure.statusCode, isNull);
      expect(failure.code, isNull);
      expect(failure.path, isNull);
      expect(failure.message, 'Nije moguce spojiti se na backend.');
    }, (_) => fail('Expected Left'));
  });
}
