import 'package:dartz/dartz.dart';

import '../../../../core/api/failure.dart';
import '../../../../core/api/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
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
  FutureEither<AuthSession?> bootstrapSession() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null) {
        return const Right(null);
      }

      final user = (await _remoteDataSource.getCurrentUser(
        accessToken,
      )).toEntity();
      final session = _sessionForUser(accessToken, user);
      if (session == null) {
        await _tokenStorage.clear();
        return const Left(
          Failure('Korisnik nema pristup kandidatskoj aplikaciji.'),
        );
      }

      return Right(session);
    } catch (error) {
      await _tokenStorage.clear();
      return Left(Failure.fromException(error));
    }
  }

  @override
  FutureEither<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      final user = response.user.toEntity();
      final session = _sessionForUser(response.accessToken, user);
      if (session == null) {
        return const Left(
          Failure('Korisnik nema pristup kandidatskoj aplikaciji.'),
        );
      }

      await _tokenStorage.saveAccessToken(response.accessToken);
      return Right(session);
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<void> logout() {
    return _tokenStorage.clear();
  }

  AuthSession? _sessionForUser(String accessToken, CurrentUser user) {
    final candidateMembership = user.candidateMembership;
    if (candidateMembership == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      user: user,
      candidateMembership: candidateMembership,
    );
  }
}
