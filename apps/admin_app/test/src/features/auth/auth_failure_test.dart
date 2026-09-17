import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/domain/entities/current_user.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/domain/usecases/bootstrap_auth_session.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/domain/usecases/login.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/domain/usecases/logout.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_state.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const user = CurrentUser(
  id: 'owner',
  email: 'owner@example.com',
  firstName: 'Test',
  lastName: 'Owner',
  phone: null,
  status: 'ACTIVE',
  memberships: [],
);

final class SessionRepository extends Fake implements AuthRepository {
  String? token = 'expired-token';
  Failure? failure = const Failure(
    'Sesija je istekla. Prijavite se ponovno.',
    statusCode: 401,
    code: 'UNAUTHORIZED',
  );
  int cleared = 0;
  @override
  Future<String?> readAccessToken() async => token;
  @override
  FutureResult<CurrentUser> getCurrentUser(String accessToken) async =>
      failure == null ? const Right(user) : Left(failure!);
  @override
  Future<void> clearSession() async {
    cleared++;
    token = null;
  }

  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  }) async => const Right(AuthSession(accessToken: 'new-token', user: user));
}

AuthCubit cubitFor(SessionRepository repository) => AuthCubit(
  bootstrapAuthSession: BootstrapAuthSession(repository),
  login: Login(repository),
  logout: Logout(repository),
);

void main() {
  late SessionRepository repository;
  setUp(() => repository = SessionRepository());
  test('initial state has no session or error', () async {
    final cubit = cubitFor(repository);
    expect(cubit.state.status, AuthStatus.initial);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.accessToken, isNull);
    await cubit.close();
  });
  for (final code in [401, 403, 503]) {
    test('bootstrap preserves all $code Failure fields', () async {
      repository.failure = Failure(
        'Backend message',
        statusCode: code,
        code: 'ERROR_$code',
        path: '/api/me',
      );
      final result = await BootstrapAuthSession(repository)();
      result.fold((failure) {
        expect(failure, same(repository.failure));
        expect(failure.statusCode, code);
        expect(failure.code, 'ERROR_$code');
        expect(failure.path, '/api/me');
      }, (_) => fail('Expected failure'));
      expect(repository.cleared, 1);
    });
  }
  blocTest<AuthCubit, AuthState>(
    'failed restoration emits visible error and login retry succeeds',
    build: () => cubitFor(repository),
    act: (cubit) async {
      await cubit.bootstrap();
      await cubit.login(email: 'owner@example.com', password: 'test-password');
    },
    expect: () => [
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.failure)
          .having(
            (s) => s.errorMessage,
            'message',
            repository.failure!.message,
          ),
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
      isA<AuthState>()
          .having((s) => s.isAuthenticated, 'authenticated', true)
          .having((s) => s.accessToken, 'token', 'new-token'),
    ],
  );
  blocTest<AuthCubit, AuthState>(
    'valid stored session is restored',
    build: () {
      repository.failure = null;
      return cubitFor(repository);
    },
    act: (cubit) => cubit.bootstrap(),
    expect: () => [
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
      isA<AuthState>().having((s) => s.isAuthenticated, 'authenticated', true),
    ],
  );
  blocTest<AuthCubit, AuthState>(
    'no stored token opens login without an error',
    build: () {
      repository.token = null;
      return cubitFor(repository);
    },
    act: (cubit) => cubit.bootstrap(),
    expect: () => [
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loading),
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.unauthenticated)
          .having((s) => s.errorMessage, 'message', isNull),
    ],
  );
  testWidgets('login visibly explains why session restoration failed', (
    tester,
  ) async {
    final cubit = cubitFor(repository);
    await cubit.bootstrap();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const LoginPage()),
      ),
    );
    expect(find.text(repository.failure!.message), findsOneWidget);
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
    expect(cubit.state.isAuthenticated, isTrue);
    expect(find.text(repository.failure!.message), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
