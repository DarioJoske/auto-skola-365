import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/lesson_detail_page.dart';

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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const LessonDetailView(),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.byType(TextFormField), 300);
    await tester.enterText(find.byType(TextFormField), 'Vježba parkiranja');
    await tester.ensureVisible(find.text('Završi sat'));
    await tester.tap(find.text('Završi sat'));
    await tester.pump();
    expect(repository.note, 'Vježba parkiranja');
    repository.result.complete(
      const Left(Failure('Spremanje nije uspjelo.', statusCode: 409)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spremanje nije uspjelo.'), findsOneWidget);
    expect(find.text('Vježba parkiranja'), findsOneWidget);
    repository.result = Completer<Either<Failure, InstructorLesson>>();
    await tester.tap(find.text('Završi sat'));
    await tester.pump();
    repository.result.complete(Right(lesson('one', 'COMPLETED')));
    await tester.pumpAndSettle();
    expect(find.text('Završi sat'), findsNothing);
    expect(find.text('Sat je označen kao odrađen.'), findsOneWidget);
    expect(repository.calls, 2);
    expect(tester.takeException(), isNull);
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
  String? note;

  @override
  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) async => Right(lesson(lessonId, 'CONFIRMED'));

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
