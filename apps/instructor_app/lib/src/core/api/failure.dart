class Failure {
  const Failure(this.message, {this.statusCode, this.code});

  factory Failure.fromException(Object error) {
    if (error is ApiFailureSource) {
      return Failure(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }

    return const Failure('Dogodila se neocekivana greska.');
  }

  final String message;
  final int? statusCode;
  final String? code;
}

abstract interface class ApiFailureSource {
  String get message;
  int? get statusCode;
  String? get code;
}
