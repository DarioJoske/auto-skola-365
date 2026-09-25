import '../../../../core/api/result.dart';
import '../entities/availability.dart';
import '../repositories/availability_repository.dart';

final class ManageAvailability {
  const ManageAvailability(this._repository);
  final AvailabilityRepository _repository;
  FutureEither<Availability> load(
    String schoolId,
    String token,
    String instructorId,
  ) => _repository.load(schoolId, token, instructorId);
  FutureEither<Availability> save(
    String schoolId,
    String token,
    String instructorId,
    Availability data,
  ) => _repository.save(schoolId, token, instructorId, data);
}
