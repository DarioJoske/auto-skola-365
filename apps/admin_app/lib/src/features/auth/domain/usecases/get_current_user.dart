import '../../../../core/api/result.dart';
import '../entities/current_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  FutureResult<CurrentUser> call(String accessToken) {
    return _repository.getCurrentUser(accessToken);
  }
}
