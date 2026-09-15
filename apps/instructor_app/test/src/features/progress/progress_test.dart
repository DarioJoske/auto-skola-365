import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/domain/entities/candidate_progress.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/domain/repositories/progress_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/domain/usecases/load_progress.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/domain/usecases/save_progress.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/progress/presentation/pages/progress_page.dart';

ProgressEntry entry(String lesson, String status, int day, int recordedDay) =>
    ProgressEntry(
      lessonId: lesson,
      lessonEndAt: DateTime(2026, 9, day),
      skill: 'PARKING',
      status: status,
      recordedAt: DateTime(2026, 9, recordedDay),
    );
CandidateProgress data({
  bool editable = true,
  List<ProgressEntry> entries = const [],
}) => CandidateProgress(
  candidateName: 'Ana',
  categoryCode: 'B',
  lessonId: 'lesson',
  editable: editable,
  skills: const [
    ProgressOption('PARKING', 'Parkiranje'),
    ProgressOption('REVERSING', 'Vožnja unatrag'),
  ],
  statuses: const [
    ProgressOption('NEEDS_PRACTICE', 'Potrebna vježba'),
    ProgressOption('MASTERED', 'Savladano'),
  ],
  entries: entries,
);

class Repository extends Fake implements ProgressRepository {
  CandidateProgress value = data();
  Failure? loadFailure;
  int saves = 0;
  Map<String, String>? sent;
  var result = Completer<Either<Failure, CandidateProgress>>();
  @override
  FutureEither<CandidateProgress> load({
    required String schoolId,
    required String accessToken,
    required String resource,
    required String id,
  }) async => loadFailure == null ? Right(value) : Left(loadFailure!);
  @override
  FutureEither<CandidateProgress> save({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required Map<String, String> assessments,
  }) {
    saves++;
    sent = assessments;
    return result.future;
  }
}

ProgressCubit cubit(Repository repo) => ProgressCubit(
  loadProgress: LoadProgress(repo),
  saveProgress: SaveProgress(repo),
  schoolId: 'school',
  accessToken: 'token',
  resource: 'lessons',
  id: 'lesson',
);
void main() {
  test('latest assessment uses lesson date instead of time of correction', () {
    final progress = data(
      entries: [
        entry('old', 'NEEDS_PRACTICE', 1, 15),
        entry('new', 'MASTERED', 10, 10),
      ],
    );
    expect(progress.latest('PARKING')!.status, 'MASTERED');
    expect(progress.latest('REVERSING'), isNull);
    expect(progress.lessonAssessments, isEmpty);
  });
  test(
    'load preselects only this lesson and read-only access prevents writes',
    () async {
      final repo = Repository()
        ..value = data(
          editable: false,
          entries: [entry('lesson', 'MASTERED', 1, 1)],
        );
      final state = cubit(repo);
      await state.load();
      expect(state.state.draft, {'PARKING': 'MASTERED'});
      state.select('PARKING', 'NEEDS_PRACTICE');
      await state.save();
      expect(repo.saves, 0);
      expect(state.state.draft, {'PARKING': 'MASTERED'});
      await state.close();
    },
  );
  test(
    'mutation sends only selected skills, prevents duplicates, and preserves failed draft',
    () async {
      final repo = Repository();
      final state = cubit(repo);
      await state.load();
      state.select('PARKING', 'NEEDS_PRACTICE');
      final pending = state.save();
      await state.save();
      expect(repo.saves, 1);
      expect(repo.sent, {'PARKING': 'NEEDS_PRACTICE'});
      repo.result.complete(
        const Left(Failure('Zabranjeno.', statusCode: 403, code: 'FORBIDDEN')),
      );
      await pending;
      expect(state.state.draft, {'PARKING': 'NEEDS_PRACTICE'});
      expect(state.state.actionFailure!.code, 'FORBIDDEN');
      expect(state.state.saving, isFalse);
      await state.close();
    },
  );
  test('load error is visible and retry succeeds', () async {
    final repo = Repository()
      ..loadFailure = const Failure('Nedostupno.', statusCode: 503);
    final state = cubit(repo);
    await state.load();
    expect(state.state.loadFailure!.message, 'Nedostupno.');
    repo.loadFailure = null;
    await state.load();
    expect(state.state.data, isNotNull);
    expect(state.state.loadFailure, isNull);
    await state.close();
  });
  test('late save after leaving screen is ignored', () async {
    final repo = Repository();
    final state = cubit(repo);
    await state.load();
    state.select('PARKING', 'MASTERED');
    final pending = state.save();
    await state.close();
    repo.result.complete(Right(data()));
    await expectLater(pending, completes);
  });
  testWidgets('instructor selects a skill and sees saved progress', (
    tester,
  ) async {
    final repo = Repository();
    final state = cubit(repo);
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: state, child: const ProgressView()),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Savladano').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Spremi napredak'));
    await tester.tap(find.text('Spremi napredak'));
    await tester.pump();
    expect(repo.sent, {'PARKING': 'MASTERED'});
    repo.result.complete(
      Right(data(entries: [entry('lesson', 'MASTERED', 10, 10)])),
    );
    await tester.pumpAndSettle();
    expect(find.text('Napredak je spremljen.'), findsOneWidget);
    expect(state.state.data!.latest('PARKING')!.status, 'MASTERED');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await state.close();
  });
}
