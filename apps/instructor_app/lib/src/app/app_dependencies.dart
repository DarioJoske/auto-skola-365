import '../features/progress/data/datasources/progress_remote_data_source.dart';
import '../features/progress/data/repositories/progress_repository_impl.dart';
import '../features/progress/domain/repositories/progress_repository.dart';
import '../features/progress/domain/usecases/load_progress.dart';
import '../features/progress/domain/usecases/save_progress.dart';
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
import '../features/candidates/data/datasources/instructor_candidates_remote_data_source.dart';
import '../features/candidates/data/repositories/instructor_candidates_repository_impl.dart';
import '../features/candidates/domain/repositories/instructor_candidates_repository.dart';
import '../features/candidates/domain/usecases/list_instructor_candidates.dart';
import '../features/schedule/data/datasources/instructor_lessons_remote_data_source.dart';
import '../features/schedule/data/repositories/instructor_lessons_repository_impl.dart';
import '../features/schedule/domain/repositories/instructor_lessons_repository.dart';
import '../features/schedule/domain/usecases/cancel_instructor_lesson.dart';
import '../features/schedule/domain/usecases/confirm_instructor_lesson.dart';
import '../features/schedule/domain/usecases/complete_instructor_lesson.dart';
import '../features/schedule/domain/usecases/get_instructor_lesson.dart';
import '../features/schedule/domain/usecases/list_instructor_lessons.dart';

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
    ..registerLazySingleton<InstructorLessonsRemoteDataSource>(
      () => InstructorLessonsRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<InstructorLessonsRepository>(
      () => InstructorLessonsRepositoryImpl(
        getIt<InstructorLessonsRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ListInstructorLessons>(
      () => ListInstructorLessons(getIt<InstructorLessonsRepository>()),
    )
    ..registerLazySingleton<GetInstructorLesson>(
      () => GetInstructorLesson(getIt<InstructorLessonsRepository>()),
    )
    ..registerLazySingleton<CompleteInstructorLesson>(
      () => CompleteInstructorLesson(getIt<InstructorLessonsRepository>()),
    )
    ..registerLazySingleton<ConfirmInstructorLesson>(
      () => ConfirmInstructorLesson(getIt<InstructorLessonsRepository>()),
    )
    ..registerLazySingleton<CancelInstructorLesson>(
      () => CancelInstructorLesson(getIt<InstructorLessonsRepository>()),
    )
    ..registerLazySingleton<InstructorCandidatesRemoteDataSource>(
      () => InstructorCandidatesRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<InstructorCandidatesRepository>(
      () => InstructorCandidatesRepositoryImpl(
        getIt<InstructorCandidatesRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ListInstructorCandidates>(
      () => ListInstructorCandidates(getIt<InstructorCandidatesRepository>()),
    )
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(getIt<ProgressRemoteDataSource>()),
    )
    ..registerLazySingleton<LoadProgress>(
      () => LoadProgress(getIt<ProgressRepository>()),
    )
    ..registerLazySingleton<SaveProgress>(
      () => SaveProgress(getIt<ProgressRepository>()),
    )
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        bootstrapAuthSession: getIt<BootstrapAuthSession>(),
        login: getIt<Login>(),
        logout: getIt<Logout>(),
      ),
    );
}
