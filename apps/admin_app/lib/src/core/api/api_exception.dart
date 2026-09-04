import 'failure.dart';

class ApiException implements Exception, ApiFailureSource {
  const ApiException(this.message, {this.statusCode});

  @override
  final String message;

  @override
  final int? statusCode;

  @override
  String toString() => message;
}
