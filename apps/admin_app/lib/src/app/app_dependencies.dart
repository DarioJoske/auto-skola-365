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
import '../features/candidates/data/datasources/candidates_remote_data_source.dart';
import '../features/candidates/data/repositories/candidates_repository_impl.dart';
import '../features/candidates/domain/repositories/candidates_repository.dart';
import '../features/candidates/domain/usecases/create_candidate.dart';
import '../features/candidates/domain/usecases/list_candidates.dart';
import '../features/candidates/domain/usecases/update_candidate.dart';
import '../features/instructors/data/datasources/instructors_remote_data_source.dart';
import '../features/instructors/data/repositories/instructors_repository_impl.dart';
import '../features/instructors/domain/repositories/instructors_repository.dart';
import '../features/instructors/domain/usecases/create_instructor.dart';
import '../features/instructors/domain/usecases/list_instructors.dart';
import '../features/instructors/domain/usecases/update_instructor.dart';
import '../features/lessons/data/datasources/lessons_remote_data_source.dart';
import '../features/lessons/data/repositories/lessons_repository_impl.dart';
import '../features/lessons/domain/repositories/lessons_repository.dart';
import '../features/lessons/domain/usecases/cancel_lesson.dart';
import '../features/lessons/domain/usecases/confirm_lesson.dart';
import '../features/lessons/domain/usecases/create_lesson.dart';
import '../features/lessons/domain/usecases/list_lessons.dart';
import '../features/lessons/domain/usecases/update_lesson.dart';

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
    )
    ..registerLazySingleton<CandidatesRemoteDataSource>(
      () => CandidatesRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<CandidatesRepository>(
      () => CandidatesRepositoryImpl(getIt<CandidatesRemoteDataSource>()),
    )
    ..registerLazySingleton<ListCandidates>(
      () => ListCandidates(getIt<CandidatesRepository>()),
    )
    ..registerLazySingleton<CreateCandidateUseCase>(
      () => CreateCandidateUseCase(getIt<CandidatesRepository>()),
    )
    ..registerLazySingleton<UpdateCandidateUseCase>(
      () => UpdateCandidateUseCase(getIt<CandidatesRepository>()),
    )
    ..registerLazySingleton<InstructorsRemoteDataSource>(
      () => InstructorsRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<InstructorsRepository>(
      () => InstructorsRepositoryImpl(getIt<InstructorsRemoteDataSource>()),
    )
    ..registerLazySingleton<ListInstructors>(
      () => ListInstructors(getIt<InstructorsRepository>()),
    )
    ..registerLazySingleton<CreateInstructorUseCase>(
      () => CreateInstructorUseCase(getIt<InstructorsRepository>()),
    )
    ..registerLazySingleton<UpdateInstructorUseCase>(
      () => UpdateInstructorUseCase(getIt<InstructorsRepository>()),
    )
    ..registerLazySingleton<LessonsRemoteDataSource>(
      () => LessonsRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<LessonsRepository>(
      () => LessonsRepositoryImpl(getIt<LessonsRemoteDataSource>()),
    )
    ..registerLazySingleton<ListLessons>(
      () => ListLessons(getIt<LessonsRepository>()),
    )
    ..registerLazySingleton<CreateLessonUseCase>(
      () => CreateLessonUseCase(getIt<LessonsRepository>()),
    )
    ..registerLazySingleton<UpdateLessonUseCase>(
      () => UpdateLessonUseCase(getIt<LessonsRepository>()),
    )
    ..registerLazySingleton<ConfirmLessonUseCase>(
      () => ConfirmLessonUseCase(getIt<LessonsRepository>()),
    )
    ..registerLazySingleton<CancelLessonUseCase>(
      () => CancelLessonUseCase(getIt<LessonsRepository>()),
    );
}
