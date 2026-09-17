class Failure {
  const Failure(this.message, {this.statusCode, this.code, this.path});

  factory Failure.fromException(Object error) {
    if (error is ApiFailureSource) {
      return Failure(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
        path: error.path,
      );
    }

    return const Failure('Dogodila se neocekivana greska.');
  }

  final String message;
  final int? statusCode;
  final String? code;
  final String? path;
}

abstract interface class ApiFailureSource {
  String get message;
  int? get statusCode;
  String? get code;
  String? get path;
}
