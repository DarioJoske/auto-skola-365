class Failure {
  const Failure(this.message, {this.statusCode});

  factory Failure.fromException(Object error) {
    if (error is ApiFailureSource) {
      return Failure(error.message, statusCode: error.statusCode);
    }

    return const Failure('Dogodila se neocekivana greska.');
  }

  final String message;
  final int? statusCode;
}

abstract interface class ApiFailureSource {
  String get message;
  int? get statusCode;
}
