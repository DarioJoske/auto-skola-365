import 'package:auto_skola_design_system/design_system.dart';
import 'dart:async';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/entities/instructor_candidate.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/entities/instructor_candidate_filters.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/repositories/instructor_candidates_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/usecases/list_instructor_candidates.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/reserve_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/instructor_lessons_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/reserve_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/reservation_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/widgets/reservation_dialog.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'src/features/schedule/presentation/cubit/schedule_cubit_test.dart'
    show lesson;

const candidate = InstructorCandidate(
  id: 'candidate',
  schoolId: 'school',
  firstName: 'Ana',
  lastName: 'Anić',
  email: null,
  phone: null,
  oib: null,
  status: 'IN_DRIVING',
  categoryCode: 'B',
  categoryName: 'B',
  assignedInstructorId: 'instructor',
  assignedInstructorName: 'Ivan',
  notes: null,
);

class CandidatesRepository extends Fake
    implements InstructorCandidatesRepository {
  FutureEither<List<InstructorCandidate>> Function()? onLoad;
  @override
  FutureEither<List<InstructorCandidate>> list({
    required String schoolId,
    required String accessToken,
    required InstructorCandidateFilters filters,
  }) => onLoad?.call() ?? Future.value(const Right([candidate]));
}

class ReservationsRepository extends Fake
    implements InstructorLessonsRepository {
  int calls = 0;
  ReserveLesson? reservation;
  FutureEither<InstructorLesson> Function()? onReserve;
  @override
  FutureEither<InstructorLesson> reserve({
    required String schoolId,
    required String accessToken,
    required ReserveLesson reservation,
  }) {
    calls++;
    this.reservation = reservation;
    return onReserve?.call() ??
        Future.value(Right(lesson('created', 'CONFIRMED')));
  }
}

void main() {
  late CandidatesRepository candidates;
  late ReservationsRepository reservations;
  ReservationCubit build() => ReservationCubit(
    listCandidates: ListInstructorCandidates(candidates),
    reserveLesson: ReserveInstructorLesson(reservations),
    schoolId: 'school',
    accessToken: 'token',
  );
  ReserveLesson request() => ReserveLesson(
    candidateId: 'candidate',
    startAt: DateTime.now().add(const Duration(days: 1)),
  );
  setUp(() {
    candidates = CandidatesRepository();
    reservations = ReservationsRepository();
  });
  test('initial state has no candidates, failures or submission', () async {
    final cubit = build();
    expect(cubit.state.candidates, isEmpty);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.saved, isFalse);
    expect(cubit.state.loadFailure, isNull);
    await cubit.close();
  });
  blocTest<ReservationCubit, ReservationState>(
    'load and reserve expose saving then success',
    build: build,
    act: (c) async {
      await c.load();
      await c.reserve(request());
    },
    expect: () => [
      isA<ReservationState>().having((s) => s.loading, 'loading', true),
      isA<ReservationState>().having((s) => s.candidates, 'candidates', [
        candidate,
      ]),
      isA<ReservationState>().having((s) => s.saving, 'saving', true),
      isA<ReservationState>().having((s) => s.saved, 'saved', true),
    ],
  );
  blocTest<ReservationCubit, ReservationState>(
    'candidate load failure can be retried',
    build: () {
      candidates.onLoad = () async =>
          const Left(Failure('Nema veze.', statusCode: 503));
      return build();
    },
    act: (c) async {
      await c.load();
      candidates.onLoad = null;
      await c.load();
    },
    expect: () => [
      isA<ReservationState>().having((s) => s.loading, 'loading', true),
      isA<ReservationState>().having(
        (s) => s.loadFailure?.statusCode,
        'failure',
        503,
      ),
      isA<ReservationState>().having((s) => s.loading, 'retry', true),
      isA<ReservationState>().having((s) => s.candidates, 'candidates', [
        candidate,
      ]),
    ],
  );
  blocTest<ReservationCubit, ReservationState>(
    'conflict preserves selection data and allows retry',
    build: () {
      reservations.onReserve = () async =>
          const Left(Failure('Termin je zauzet.', statusCode: 409));
      return build();
    },
    act: (c) async {
      await c.load();
      await c.reserve(request());
      reservations.onReserve = null;
      await c.reserve(request());
    },
    expect: () => [
      isA<ReservationState>(),
      isA<ReservationState>(),
      isA<ReservationState>().having((s) => s.saving, 'saving', true),
      isA<ReservationState>()
          .having((s) => s.saveFailure?.statusCode, 'conflict', 409)
          .having((s) => s.candidates, 'preserved', [candidate]),
      isA<ReservationState>().having((s) => s.saving, 'retrying', true),
      isA<ReservationState>().having((s) => s.saved, 'saved', true),
    ],
  );
  test(
    'superseded loads cannot restore stale candidates; closed loads do not emit',
    () async {
      final first = Completer<Either<Failure, List<InstructorCandidate>>>();
      final second = Completer<Either<Failure, List<InstructorCandidate>>>();
      final queue = [first, second];
      candidates.onLoad = () => queue.removeAt(0).future;
      final cubit = build();
      final a = cubit.load();
      final b = cubit.load();
      second.complete(const Right([]));
      await b;
      first.complete(const Right([candidate]));
      await a;
      expect(cubit.state.candidates, isEmpty);
      final pending = Completer<Either<Failure, List<InstructorCandidate>>>();
      candidates.onLoad = () => pending.future;
      final load = cubit.load();
      await cubit.close();
      pending.complete(const Right([candidate]));
      await load;
    },
  );
  test(
    'duplicate saves and foreign candidates never submit extra requests',
    () async {
      final pending = Completer<Either<Failure, InstructorLesson>>();
      reservations.onReserve = () => pending.future;
      final cubit = build();
      await cubit.load();
      await cubit.reserve(
        ReserveLesson(candidateId: 'foreign', startAt: request().startAt),
      );
      expect(reservations.calls, 0);
      final saving = cubit.reserve(request());
      await cubit.reserve(request());
      await cubit.load();
      expect(reservations.calls, 1);
      pending.complete(Right(lesson('created', 'CONFIRMED')));
      await saving;
      await cubit.reserve(request());
      expect(reservations.calls, 1);
      await cubit.close();
    },
  );
  testWidgets(
    'candidate selection and reservation failure stay visible, retry closes dialog',
    (tester) async {
      final cubit = build();
      await cubit.load();
      reservations.onReserve = () async =>
          const Left(Failure('Termin je zauzet.', statusCode: 409));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: ReservationDialog(
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                    ),
                  ),
                ),
                child: const Text('Otvori'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Otvori'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppDropdownFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Anić').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rezerviraj'));
      await tester.pumpAndSettle();
      expect(find.text('Termin je zauzet.'), findsOneWidget);
      expect(find.byType(ReservationDialog), findsOneWidget);
      expect(reservations.reservation?.candidateId, 'candidate');
      reservations.onReserve = null;
      await tester.tap(find.text('Rezerviraj'));
      await tester.pumpAndSettle();
      expect(find.byType(ReservationDialog), findsNothing);
      await cubit.close();
    },
  );
  testWidgets('empty assigned candidates disables reservation', (tester) async {
    candidates.onLoad = () async => const Right([]);
    final cubit = build();
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ReservationDialog(initialDate: DateTime.now()),
          ),
        ),
      ),
    );
    expect(
      find.text('Nemate dodijeljenih kandidata za rezervaciju.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Rezerviraj'))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
