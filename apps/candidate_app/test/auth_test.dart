import 'dart:async';
import 'package:auto_skola_365_candidate_app/src/core/api/failure.dart';
import 'package:auto_skola_365_candidate_app/src/core/api/result.dart';
import 'package:auto_skola_365_candidate_app/src/core/storage/token_storage.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/data/models/login_response_model.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/entities/auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/bootstrap_auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/login.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/logout.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/presentation/cubit/auth_state.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthFake extends Fake implements AuthRepository {
  FutureEither<AuthSession> Function()? onLogin;
  int calls = 0;
  @override
  FutureEither<AuthSession?> bootstrapSession() async => const Right(null);
  @override
  FutureEither<AuthSession> login({
    required String email,
    required String password,
  }) {
    calls++;
    return onLogin?.call() ??
        Future.value(const Left(Failure('Pogrešna lozinka.', statusCode: 401)));
  }

  @override
  Future<void> logout() async {}
}

class Storage extends Fake implements TokenStorage {
  String? token;
  @override
  Future<void> saveAccessToken(String token) async {
    this.token = token;
  }
}

class Remote extends Fake implements AuthRemoteDataSource {
  String role = 'candidate';
  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async => LoginResponseModel.fromJson({
    'accessToken': 'token',
    'tokenType': 'Bearer',
    'expiresIn': 3600,
    'user': {
      'id': 'user',
      'email': email,
      'firstName': 'Ana',
      'lastName': 'Anić',
      'phone': null,
      'status': 'ACTIVE',
      'memberships': [
        {
          'id': 'membership',
          'schoolId': 'school',
          'schoolName': 'Autoškola',
          'membershipStatus': 'ACTIVE',
          'roleKey': role,
          'roleName': role,
          'roleScope': 'SCHOOL',
          'permissions': role == 'candidate'
              ? ['lessons.reserve_own']
              : ['lessons.view_assigned'],
        },
      ],
    },
  });
}

void main() {
  late AuthFake repository;
  AuthCubit build() => AuthCubit(
    bootstrapAuthSession: BootstrapAuthSession(repository),
    login: Login(repository),
    logout: Logout(repository),
  );
  setUp(() => repository = AuthFake());
  test('initial auth state', () async {
    final c = build();
    expect(c.state.status, AuthStatus.initial);
    await c.close();
  });
  blocTest<AuthCubit, AuthState>(
    'bootstrap without token opens login',
    build: build,
    act: (c) => c.bootstrap(),
    expect: () => [
      isA<AuthState>().having((s) => s.status, 'loading', AuthStatus.loading),
      isA<AuthState>().having(
        (s) => s.status,
        'signed out',
        AuthStatus.unauthenticated,
      ),
    ],
  );
  blocTest<AuthCubit, AuthState>(
    'invalid credentials visibly fail and can retry',
    build: build,
    act: (c) async {
      await c.login(email: 'ana@example.com', password: 'bad');
      await c.login(email: 'ana@example.com', password: 'bad');
    },
    expect: () => [
      isA<AuthState>().having((s) => s.status, 'loading', AuthStatus.loading),
      isA<AuthState>().having(
        (s) => s.errorMessage,
        'error',
        'Pogrešna lozinka.',
      ),
      isA<AuthState>(),
      isA<AuthState>().having(
        (s) => s.errorMessage,
        'retry error',
        'Pogrešna lozinka.',
      ),
    ],
  );
  test('duplicate login and closing during login are handled', () async {
    final pending = Completer<Either<Failure, AuthSession>>();
    repository.onLogin = () => pending.future;
    final c = build();
    final login = c.login(email: 'a', password: 'b');
    await c.login(email: 'a', password: 'b');
    expect(repository.calls, 1);
    await c.close();
    pending.complete(const Left(Failure('Error')));
    await login;
  });
  test(
    'candidate role can log in; instructor role cannot enter candidate app',
    () async {
      final remote = Remote();
      final storage = Storage();
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        tokenStorage: storage,
      );
      expect(
        (await repository.login(
          email: 'a@b.hr',
          password: 'Password123',
        )).isRight(),
        true,
      );
      expect(storage.token, 'token');
      storage.token = null;
      remote.role = 'instructor';
      expect(
        (await repository.login(
          email: 'a@b.hr',
          password: 'Password123',
        )).isLeft(),
        true,
      );
      expect(storage.token, isNull);
    },
  );
  testWidgets('login validates fields and shows API failure', (tester) async {
    final c = build();
    await tester.pumpWidget(
      MaterialApp(
        theme: DrivingSchoolTheme.light(),
        home: BlocProvider.value(value: c, child: const LoginPage()),
      ),
    );
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lozinka'),
      'incorrect',
    );
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
    expect(find.text('Pogrešna lozinka.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
}
