import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> getJson(
    String path, {
    String? accessToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _headers(accessToken)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: _headers(accessToken)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<dynamic> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: body,
        options: Options(headers: _headers(accessToken)),
      );
      return response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Map<String, String> _headers(String? accessToken) {
    return {if (accessToken != null) 'Authorization': 'Bearer $accessToken'};
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    return ApiException(_messageForStatus(statusCode), statusCode: statusCode);
  }

  String _messageForStatus(int? statusCode) {
    return switch (statusCode) {
      401 => 'Sesija je istekla. Prijavi se ponovno.',
      403 => 'Nemas dozvolu za ovu akciju.',
      null => 'Nije moguce spojiti se na backend.',
      _ => 'API zahtjev nije uspio ($statusCode).',
    };
  }
}
