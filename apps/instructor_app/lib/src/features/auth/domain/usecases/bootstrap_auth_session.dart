import '../../../../core/api/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class BootstrapAuthSession {
  const BootstrapAuthSession(this._repository);

  final AuthRepository _repository;

  FutureEither<AuthSession?> call() {
    return _repository.bootstrapSession();
  }
}
