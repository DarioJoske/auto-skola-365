import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _tokenStorage.saveAccessToken(response.accessToken);

      return success(
        AuthSession(
          accessToken: response.accessToken,
          user: response.user.toEntity(),
        ),
      );
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  FutureResult<CurrentUser> getCurrentUser(String accessToken) async {
    try {
      final response = await _remoteDataSource.me(accessToken);
      return success(response.toEntity());
    } catch (error) {
      return failure(Failure.fromException(error));
    }
  }

  @override
  Future<String?> readAccessToken() {
    return _tokenStorage.readAccessToken();
  }

  @override
  Future<void> clearSession() {
    return _tokenStorage.clear();
  }
}
