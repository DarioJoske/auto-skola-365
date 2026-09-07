import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/bootstrap_auth_session.dart';
import '../features/auth/domain/usecases/login.dart';
import '../features/auth/domain/usecases/logout.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<AuthCubit>()) {
    return;
  }

  getIt
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        ),
      ),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()))
    ..registerLazySingleton<TokenStorage>(TokenStorage.new)
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        tokenStorage: getIt<TokenStorage>(),
      ),
    )
    ..registerLazySingleton<BootstrapAuthSession>(
      () => BootstrapAuthSession(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<Login>(() => Login(getIt<AuthRepository>()))
    ..registerLazySingleton<Logout>(() => Logout(getIt<AuthRepository>()))
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        bootstrapAuthSession: getIt<BootstrapAuthSession>(),
        login: getIt<Login>(),
        logout: getIt<Logout>(),
      ),
    );
}
