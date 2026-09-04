import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../repositories/auth_repository.dart';

class BootstrapAuthSession {
  const BootstrapAuthSession(this._repository);

  final AuthRepository _repository;

  FutureResult<AuthSession?> call() async {
    final accessToken = await _repository.readAccessToken();
    if (accessToken == null) {
      return success(null);
    }

    final userResult = await _repository.getCurrentUser(accessToken);
    return userResult.fold((failureValue) async {
      await _repository.clearSession();
      return failure<AuthSession?>(Failure(failureValue.message));
    }, (user) => success(AuthSession(accessToken: accessToken, user: user)));
  }
}
