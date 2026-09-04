import '../../../../core/api/result.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  FutureResult<AuthSession> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
