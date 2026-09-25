import 'package:dartz/dartz.dart';
import '../../../../core/api/result.dart';
import '../../../../core/api/failure.dart';
import '../../domain/entities/availability.dart';
import '../../domain/repositories/availability_repository.dart';
import '../datasources/availability_remote_data_source.dart';
import '../models/availability_model.dart';

final class AvailabilityRepositoryImpl implements AvailabilityRepository {
  const AvailabilityRepositoryImpl(this._remote);
  final AvailabilityRemoteDataSource _remote;
  @override
  FutureEither<Availability> load(
    String schoolId,
    String token,
    String instructorId,
  ) async {
    try {
      return Right((await _remote.load(schoolId, token, instructorId)).data);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  FutureEither<Availability> save(
    String schoolId,
    String token,
    String instructorId,
    Availability data,
  ) async {
    try {
      return Right(
        (await _remote.save(
          schoolId,
          token,
          instructorId,
          AvailabilityModel(data),
        )).data,
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
