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
import '../features/candidates/domain/usecases/load_candidate.dart';
import '../features/candidates/domain/usecases/update_candidate.dart';
import '../features/dashboard/data/datasources/school_overview_remote_data_source.dart';
import '../features/dashboard/data/repositories/school_overview_repository_impl.dart';
import '../features/dashboard/domain/repositories/school_overview_repository.dart';
import '../features/dashboard/domain/usecases/load_school_overview.dart';
import '../features/instructors/data/datasources/instructor_overview_remote_data_source.dart';
import '../features/instructors/data/datasources/instructors_remote_data_source.dart';
import '../features/instructors/data/repositories/instructor_overview_repository_impl.dart';
import '../features/instructors/data/repositories/instructors_repository_impl.dart';
import '../features/instructors/domain/repositories/instructor_overview_repository.dart';
import '../features/instructors/domain/repositories/instructors_repository.dart';
import '../features/instructors/domain/usecases/create_instructor.dart';
import '../features/instructors/domain/usecases/list_instructors.dart';
import '../features/instructors/domain/usecases/load_instructor_overview.dart';
import '../features/instructors/domain/usecases/update_instructor.dart';
import '../features/lessons/data/datasources/lessons_remote_data_source.dart';
import '../features/lessons/data/repositories/lessons_repository_impl.dart';
import '../features/lessons/domain/repositories/lessons_repository.dart';
import '../features/lessons/domain/usecases/cancel_lesson.dart';
import '../features/lessons/domain/usecases/confirm_lesson.dart';
import '../features/lessons/domain/usecases/create_lesson.dart';
import '../features/lessons/domain/usecases/list_lessons.dart';
import '../features/lessons/domain/usecases/update_lesson.dart';
import '../features/progress/data/datasources/progress_remote_data_source.dart';
import '../features/progress/data/repositories/progress_repository_impl.dart';
import '../features/progress/domain/repositories/progress_repository.dart';
import '../features/progress/domain/usecases/load_progress.dart';

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
    ..registerLazySingleton<ProgressRemoteDataSource>(
      () => ProgressRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(getIt<ProgressRemoteDataSource>()),
    )
    ..registerLazySingleton<LoadProgress>(
      () => LoadProgress(getIt<ProgressRepository>()),
    )
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
    ..registerLazySingleton<LoadCandidate>(
      () => LoadCandidate(getIt<CandidatesRepository>()),
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
  getIt.registerLazySingleton<SchoolOverviewRemoteDataSource>(
    () => SchoolOverviewRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<SchoolOverviewRepository>(
    () => SchoolOverviewRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<LoadSchoolOverview>(
    () => LoadSchoolOverview(getIt()),
  );
  getIt.registerLazySingleton<InstructorOverviewRemoteDataSource>(
    () => InstructorOverviewRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<InstructorOverviewRepository>(
    () => InstructorOverviewRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<LoadInstructorOverview>(
    () => LoadInstructorOverview(getIt()),
  );
}
