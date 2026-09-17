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
    return ApiException(
      _messageFromResponse(error.response?.data) ??
          _messageForStatus(statusCode),
      statusCode: statusCode,
      code: _codeFromResponse(error.response?.data),
      path: _pathFromResponse(error.response?.data),
    );
  }

  String? _messageFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return null;
  }

  String? _codeFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final code = data['code'];
      if (code is String && code.trim().isNotEmpty) {
        return code;
      }
    }

    return null;
  }

  String? _pathFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final path = data['path'];
      if (path is String && path.trim().isNotEmpty) {
        return path;
      }
    }
    return null;
  }

  String _messageForStatus(int? statusCode) {
    return switch (statusCode) {
      401 => 'Sesija je istekla. Prijavi se ponovno.',
      403 => 'Nemas dozvolu za ovu akciju.',
      409 => 'Termin se preklapa s postojecim terminom.',
      null => 'Nije moguce spojiti se na backend.',
      _ => 'API zahtjev nije uspio ($statusCode).',
    };
  }
}
