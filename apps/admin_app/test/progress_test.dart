import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_state.dart';
import 'dart:async';

import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/data/models/progress_model.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/domain/entities/candidate_progress.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/domain/repositories/progress_repository.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/domain/usecases/load_progress.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/progress/presentation/widgets/driving_hours_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

CandidateProgress hours(int count, {int? target = 35}) => CandidateProgress(
  candidateId: 'candidate',
  candidateName: 'Ana Anić',
  categoryCode: 'B',
  completedDrivingHours: count,
  requiredDrivingHours: target,
);

class HoursRepository extends Fake implements ProgressRepository {
  CandidateProgress value = hours(25);
  Failure? failure;
  FutureEither<CandidateProgress> Function()? onLoad;

  @override
  FutureEither<CandidateProgress> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) =>
      onLoad?.call() ??
      Future.value(failure == null ? Right(value) : Left(failure!));
}

ProgressCubit hoursCubit(HoursRepository repository) => ProgressCubit(
  loadProgress: LoadProgress(repository),
  schoolId: 'school',
  accessToken: 'token',
  resource: 'candidates',
  id: 'candidate',
);

class RecordingAuthCubit extends Cubit<AuthState> implements AuthCubit {
  RecordingAuthCubit(this.onLogout) : super(const AuthState.initial());
  final VoidCallback onLogout;
  int logoutCalls = 0;
  @override
  Future<void> bootstrap() async {}
  @override
  Future<void> login({required String email, required String password}) async {}
  @override
  Future<void> logout() async {
    onLogout();
    logoutCalls++;
    emit(const AuthState.unauthenticated());
  }
}

void main() {
  late HoursRepository repository;
  setUp(() => repository = HoursRepository());

  testWidgets(
    '401 displays session expiry before logout and clears candidate data',
    (tester) async {
      final cubit = hoursCubit(repository);
      final auth = RecordingAuthCubit(() {
        expect(find.byType(ScaffoldMessenger), findsOneWidget);
        expect(cubit.state.loadFailure?.statusCode, 401);
      });
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: auth),
                BlocProvider.value(value: cubit),
              ],
              child: const DrivingHoursPanel(),
            ),
          ),
        ),
      );
      repository.failure = const Failure(
        'JWT rejected',
        statusCode: 401,
        code: 'UNAUTHORIZED',
      );
      await cubit.load();
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Sesija je istekla. Prijavite se ponovno.'),
        ),
        findsOneWidget,
      );
      expect(find.text('25/35 sati odrađeno'), findsNothing);
      expect(auth.logoutCalls, 1);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      await auth.close();
    },
  );

  testWidgets(
    '403 removes protected hours and shows the backend reason with retry',
    (tester) async {
      final cubit = hoursCubit(repository);
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const DrivingHoursPanel(),
            ),
          ),
        ),
      );
      repository.failure = const Failure(
        'Kandidat više nije dodijeljen vama.',
        statusCode: 403,
        code: 'FORBIDDEN',
      );
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.text('Kandidat više nije dodijeljen vama.'), findsOneWidget);
      expect(find.text('25/35 sati odrađeno'), findsNothing);
      expect(find.text('Pokušaj ponovno'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );

  test(
    'initial state has no fabricated hours and no pending request',
    () async {
      final cubit = hoursCubit(repository);
      expect(cubit.state.data, isNull);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.loadFailure, isNull);
      await cubit.close();
    },
  );

  test('API model accepts hour totals without any assessment fields', () {
    final result = ProgressModel.fromJson({
      'candidateId': 'candidate',
      'candidateName': 'Ana Anić',
      'categoryCode': 'B',
      'completedDrivingHours': 25,
      'requiredDrivingHours': 35,
    }).toEntity();
    expect(result.completedDrivingHours, 25);
    expect(result.requiredDrivingHours, 35);
  });

  blocTest<ProgressCubit, ProgressState>(
    'loads the backend total after the loading state',
    build: () => hoursCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ProgressState>().having((s) => s.loading, 'loading', true),
      isA<ProgressState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.data?.completedDrivingHours, 'hours', 25),
    ],
  );

  blocTest<ProgressCubit, ProgressState>(
    'load failure preserves backend details and retry loads the hours',
    build: () {
      repository.failure = const Failure(
        'Usluga nije dostupna.',
        statusCode: 503,
        code: 'UNAVAILABLE',
      );
      return hoursCubit(repository);
    },
    act: (cubit) async {
      await cubit.load();
      repository.failure = null;
      await cubit.load();
    },
    expect: () => [
      isA<ProgressState>().having((s) => s.loading, 'loading', true),
      isA<ProgressState>()
          .having((s) => s.loadFailure?.code, 'code', 'UNAVAILABLE')
          .having((s) => s.loadFailure?.statusCode, 'status', 503),
      isA<ProgressState>().having((s) => s.loading, 'loading', true),
      isA<ProgressState>()
          .having((s) => s.data?.completedDrivingHours, 'hours', 25)
          .having((s) => s.loadFailure, 'failure', isNull),
    ],
  );

  blocTest<ProgressCubit, ProgressState>(
    'refresh keeps known hours while loading and on recoverable failure',
    build: () => hoursCubit(repository),
    seed: () => ProgressState(data: hours(25)),
    act: (cubit) async {
      repository.failure = const Failure('Pokušajte ponovno.', statusCode: 503);
      await cubit.load();
    },
    expect: () => [
      isA<ProgressState>()
          .having((s) => s.loading, 'loading', true)
          .having((s) => s.data?.completedDrivingHours, 'hours', 25),
      isA<ProgressState>()
          .having((s) => s.data?.completedDrivingHours, 'hours', 25)
          .having(
            (s) => s.loadFailure?.message,
            'failure',
            'Pokušajte ponovno.',
          ),
    ],
  );

  blocTest<ProgressCubit, ProgressState>(
    'a stale response cannot replace refreshed hours after completion',
    build: () => hoursCubit(repository),
    act: (cubit) async {
      final old = Completer<Either<Failure, CandidateProgress>>();
      repository.onLoad = () => old.future;
      final pending = cubit.load();
      repository.onLoad = () async => Right(hours(26));
      await cubit.load();
      old.complete(Right(hours(25)));
      await pending;
    },
    expect: () => [
      isA<ProgressState>().having((s) => s.loading, 'loading', true),
      isA<ProgressState>().having((s) => s.loading, 'loading', true),
      isA<ProgressState>().having(
        (s) => s.data?.completedDrivingHours,
        'hours',
        26,
      ),
    ],
  );

  for (final status in [401, 403]) {
    blocTest<ProgressCubit, ProgressState>(
      'revoked access ($status) clears previously displayed candidate data',
      build: () => hoursCubit(repository),
      seed: () => ProgressState(data: hours(25)),
      act: (cubit) async {
        repository.failure = Failure('Nema pristupa.', statusCode: status);
        await cubit.load();
      },
      expect: () => [
        isA<ProgressState>().having((s) => s.loading, 'loading', true),
        isA<ProgressState>()
            .having((s) => s.data, 'data', isNull)
            .having((s) => s.loadFailure?.statusCode, 'status', status),
      ],
    );
  }

  test('leaving the screen ignores an outstanding response', () async {
    final pending = Completer<Either<Failure, CandidateProgress>>();
    repository.onLoad = () => pending.future;
    final cubit = hoursCubit(repository);
    final load = cubit.load();
    await cubit.close();
    pending.complete(Right(hours(25)));
    await expectLater(load, completes);
  });

  for (final count in [0, 25, 35, 37]) {
    testWidgets('shows $count/35 hours with no skill assessment controls', (
      tester,
    ) async {
      repository.value = hours(count);
      final cubit = hoursCubit(repository);
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const DrivingHoursPanel(),
            ),
          ),
        ),
      );
      expect(find.text('$count/35 sati odrađeno'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Spremi napredak'), findsNothing);
      expect(find.text('Povijest procjena'), findsNothing);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, (count / 35).clamp(0.0, 1.0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
  }

  testWidgets('unknown target shows hours without an invented goal', (
    tester,
  ) async {
    repository.value = hours(7, target: null);
    final cubit = hoursCubit(repository);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const DrivingHoursPanel(),
          ),
        ),
      ),
    );
    expect(find.text('7 sati odrađeno'), findsOneWidget);
    expect(find.text('Cilj sati nije postavljen.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  testWidgets(
    'refresh failure leaves the counter visible and retry updates it',
    (tester) async {
      final cubit = hoursCubit(repository);
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const DrivingHoursPanel(),
            ),
          ),
        ),
      );
      repository.failure = const Failure('Veza je prekinuta.', statusCode: 503);
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.text('Veza je prekinuta.'), findsOneWidget);
      expect(find.text('25/35 sati odrađeno'), findsOneWidget);
      repository.failure = null;
      repository.value = hours(26);
      await tester.tap(find.text('Pokušaj ponovno'));
      await tester.pumpAndSettle();
      expect(find.text('26/35 sati odrađeno'), findsOneWidget);
      expect(find.text('Veza je prekinuta.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );
}
