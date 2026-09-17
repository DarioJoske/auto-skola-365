import 'failure.dart';

class ApiException implements Exception, ApiFailureSource {
  const ApiException(this.message, {this.statusCode, this.code});

  @override
  final String message;

  @override
  final int? statusCode;

  @override
  final String? code;

  @override
  String toString() => message;
}
