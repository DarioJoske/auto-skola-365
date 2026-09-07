import '../../../../core/api/result.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  FutureEither<AuthSession> login({
    required String email,
    required String password,
  });

  FutureEither<AuthSession?> bootstrapSession();

  Future<void> logout();
}
