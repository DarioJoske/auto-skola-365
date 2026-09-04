import '../../../../core/api/result.dart';
import '../entities/current_user.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final CurrentUser user;
}

abstract interface class AuthRepository {
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  });

  FutureResult<CurrentUser> getCurrentUser(String accessToken);

  Future<String?> readAccessToken();

  Future<void> clearSession();
}
