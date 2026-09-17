import 'failure.dart';

class ApiException implements Exception, ApiFailureSource {
  const ApiException(this.message, {this.statusCode, this.code, this.path});

  @override
  final String message;

  @override
  final int? statusCode;

  @override
  final String? code;

  @override
  final String? path;

  @override
  String toString() => message;
}
