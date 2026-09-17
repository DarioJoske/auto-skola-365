import 'package:dartz/dartz.dart';

import 'failure.dart';

extension EitherFailureResolver<T> on Either<Failure, T> {
  R resolve<R>({
    required R Function(String message) onFailure,
    required R Function(T value) onSuccess,
  }) {
    return fold((failure) => onFailure(failure.message), onSuccess);
  }

  R resolveWithFailure<R>({
    required R Function(Failure failure) onFailure,
    required R Function(T value) onSuccess,
  }) {
    return fold(onFailure, onSuccess);
  }
}
