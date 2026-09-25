import '../../../../core/api/result.dart';
import '../entities/availability.dart';

abstract interface class AvailabilityRepository {
  FutureEither<Availability> load(
    String schoolId,
    String token,
    String instructorId,
  );
  FutureEither<Availability> save(
    String schoolId,
    String token,
    String instructorId,
    Availability data,
  );
}
