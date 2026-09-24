import 'dart:async';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/complete_lesson_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/lesson_detail_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/presentation/bloc/progress_cubit.dart';
import '../../../progress/progress_test.dart'
    show HoursRepository, hoursCubit, hours;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/lesson_detail_view.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/instructor_lessons_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/get_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/complete_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/confirm_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/cancel_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/lesson_detail_cubit.dart';
import 'schedule_cubit_test.dart' show lesson;

void main() {
  late CompletionRepository repository;
  late LessonDetailCubit cubit;
  setUp(() {
    repository = CompletionRepository();
    cubit = LessonDetailCubit(
      getInstructorLesson: GetInstructorLesson(repository),
      completeInstructorLesson: CompleteInstructorLesson(repository),
      confirmInstructorLesson: ConfirmInstructorLesson(repository),
      cancelInstructorLesson: CancelInstructorLesson(repository),
      schoolId: 'school',
      accessToken: 'token',
      lessonId: 'one',
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test('initial detail state has no lesson or active action', () {
    expect(cubit.state.status, LessonDetailStatus.initial);
    expect(cubit.state.lesson, isNull);
    expect(cubit.state.actionInProgress, isFalse);
  });

  blocTest<LessonDetailCubit, LessonDetailState>(
    'completion wins over an older refresh and suppresses duplicate actions',
    build: () => cubit,
    act: (cubit) async {
      await cubit.load();
      final old = Completer<Either<Failure, InstructorLesson>>();
      repository.onGet = () => old.future;
      final refresh = cubit.load();
      final completion = cubit.completeLesson(null);
      await cubit.completeLesson(null);
      await cubit.load();
      repository.result.complete(Right(lesson('one', 'COMPLETED')));
      await completion;
      old.complete(Right(lesson('one', 'CONFIRMED')));
      await refresh;
    },
    expect: () => [
      isA<LessonDetailState>().having(
        (s) => s.status,
        'status',
        LessonDetailStatus.loading,
      ),
      isA<LessonDetailState>().having(
        (s) => s.lesson?.status,
        'lesson',
        'CONFIRMED',
      ),
      isA<LessonDetailState>().having(
        (s) => s.status,
        'status',
        LessonDetailStatus.loading,
      ),
      isA<LessonDetailState>().having((s) => s.actionInProgress, 'busy', true),
      isA<LessonDetailState>()
          .having((s) => s.lesson?.status, 'lesson', 'COMPLETED')
          .having((s) => s.actionInProgress, 'busy', false),
    ],
    verify: (_) => expect(repository.calls, 1),
  );

  testWidgets('completion form keeps the note after failure and allows retry', (
    tester,
  ) async {
    await cubit.close();
    repository = CompletionRepository();
    cubit = LessonDetailCubit(
      getInstructorLesson: GetInstructorLesson(repository),
      completeInstructorLesson: CompleteInstructorLesson(repository),
      confirmInstructorLesson: ConfirmInstructorLesson(repository),
      cancelInstructorLesson: CancelInstructorLesson(repository),
      schoolId: 'school',
      accessToken: 'token',
      lessonId: 'one',
    );
    await cubit.load();
    final progressRepository = HoursRepository()..value = hours(24);
    final progress = hoursCubit(progressRepository);
    await progress.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider<ProgressCubit>.value(value: progress),
            ],
            child: const CompleteLessonView(),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(find.byType(TextFormField), 'Vježba parkiranja');
    final refreshResult = Completer<Either<Failure, InstructorLesson>>();
    repository.onGet = () => refreshResult.future;
    final refresh = cubit.load();
    await tester.pump();
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    refreshResult.complete(
      const Left(Failure('Osvježavanje nije uspjelo.', statusCode: 503)),
    );
    await refresh;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    repository.onGet = null;
    await cubit.load();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    await tester.ensureVisible(find.text('Spremi i zaključi'));
    await tester.tap(find.text('Spremi i zaključi'));
    await tester.pump();
    expect(repository.note, 'Vježba parkiranja');
    repository.result.complete(
      const Left(Failure('Spremanje nije uspjelo.', statusCode: 409)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spremanje nije uspjelo.'), findsOneWidget);
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    repository.result = Completer<Either<Failure, InstructorLesson>>();
    await tester.tap(find.text('Spremi i zaključi'));
    await tester.pump();
    expect(repository.calls, 2);
    repository.result.complete(
      const Left(Failure('Pokušajte ponovno.', statusCode: 503)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await progress.close();
  });

  testWidgets('cancellation only runs after explicit confirmation', (
    tester,
  ) async {
    await cubit.load();
    final progress = hoursCubit(HoursRepository());
    addTearDown(progress.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider<ProgressCubit>.value(value: progress),
            ],
            child: const LessonDetailView(),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Otkaži termin'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Otkaži termin'));
    await tester.pumpAndSettle();
    expect(repository.cancelCalls, 0);
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(repository.cancelCalls, 0);
    await tester.tap(find.text('Otkaži termin'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Otkaži termin'));
    await tester.pumpAndSettle();
    expect(repository.cancelCalls, 1);
    expect(find.text('Dovrši vožnju'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'completion sends the note once and updates the displayed status',
    () async {
      await cubit.load();
      final pending = cubit.completeLesson('Parkiranje');
      await cubit.completeLesson('Duplicate');
      expect(repository.calls, 1);
      expect(repository.note, 'Parkiranje');
      expect(cubit.state.actionInProgress, isTrue);
      repository.result.complete(Right(lesson('one', 'COMPLETED')));
      await pending;
      expect(cubit.state.lesson!.status, 'COMPLETED');
      expect(cubit.state.actionInProgress, isFalse);
      expect(cubit.state.successMessage, isNotNull);
    },
  );

  test(
    'completion failure preserves confirmed status and exposes the error',
    () async {
      await cubit.load();
      final pending = cubit.completeLesson(null);
      repository.result.complete(
        const Left(Failure('Sat još traje.', statusCode: 409)),
      );
      await pending;
      expect(cubit.state.lesson!.status, 'CONFIRMED');
      expect(cubit.state.errorMessage, 'Sat još traje.');
      expect(cubit.state.errorStatusCode, 409);
      expect(cubit.state.actionInProgress, isFalse);
    },
  );

  test('leaving during completion does not emit after disposal', () async {
    final pending = cubit.completeLesson(null);
    await cubit.close();
    repository.result.complete(Right(lesson('one', 'COMPLETED')));
    await expectLater(pending, completes);
  });
}

class CompletionRepository extends Fake implements InstructorLessonsRepository {
  var result = Completer<Either<Failure, InstructorLesson>>();
  int calls = 0;
  int cancelCalls = 0;
  @override
  FutureEither<InstructorLesson> cancel({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async {
    cancelCalls++;
    return Right(lesson(lessonId, 'CANCELLED'));
  }

  String? note;
  FutureEither<InstructorLesson> Function()? onGet;

  @override
  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => onGet?.call() ?? Future.value(Right(lesson(lessonId, 'CONFIRMED')));

  @override
  FutureEither<InstructorLesson> complete({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    String? note,
  }) {
    calls++;
    this.note = note;
    return result.future;
  }
}
