import 'package:dartz/dartz.dart';

import 'failure.dart';

typedef Result<T> = Either<Failure, T>;
typedef FutureResult<T> = Future<Result<T>>;
typedef FutureEither<T> = Future<Result<T>>;

Result<T> success<T>(T value) => Right(value);
Result<T> failure<T>(Failure failure) => Left(failure);
