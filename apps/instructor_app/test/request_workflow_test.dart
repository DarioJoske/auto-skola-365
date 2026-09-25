import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/data/models/instructor_lesson_model.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/entities/instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/instructor_lessons_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/repositories/request_decisions_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/get_instructor_lesson.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/domain/usecases/decide_request.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/request_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/lesson_detail_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/request_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'support/instructor_workflow_fixture.dart';

class RequestsFake extends Fake
    implements InstructorLessonsRepository, RequestDecisionsRepository {
  final json = {...WorkflowAdapter().lesson, 'status': 'REQUESTED'};
  InstructorLesson get value => InstructorLessonModel.fromJson(json).toEntity();
  int calls = 0;
  Failure? failure;
  FutureEither<InstructorLesson> Function()? loading;
  FutureEither<InstructorLesson> Function()? deciding;
  @override
  FutureEither<InstructorLesson> get({
    required String schoolId,
    required String accessToken,
    required String lessonId,
  }) => loading?.call() ?? Future.value(Right(value));
  @override
  FutureEither<InstructorLesson> decide({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required RequestDecision decision,
    DateTime? startAt,
  }) async {
    calls++;
    if (deciding != null) return deciding!();
    if (failure != null) return Left(failure!);
    if (decision == RequestDecision.propose) {
      json['proposedStartAt'] = startAt!.toUtc().toIso8601String();
    } else {
      json['status'] = decision == RequestDecision.confirm
          ? 'CONFIRMED'
          : 'CANCELLED';
    }
    return Right(value);
  }
}

RequestCubit make(RequestsFake repo) => RequestCubit(
  load: GetInstructorLesson(repo),
  decide: DecideRequest(repo),
  schoolId: 'school',
  accessToken: 'token',
  lessonId: 'lesson',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('packages/auto_skola_design_system/SchoolSans')
          ..addFont(
            rootBundle.load(
              'packages/auto_skola_design_system/assets/fonts/Roboto-Regular.ttf',
            ),
          )
          ..addFont(
            rootBundle.load(
              'packages/auto_skola_design_system/assets/fonts/Roboto-Bold.ttf',
            ),
          ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  late RequestsFake repo;
  setUp(() => repo = RequestsFake());
  test('initial state', () {
    final c = make(repo);
    expect(c.state.status, LessonDetailStatus.initial);
    expect(c.state.lesson, isNull);
    c.close();
  });
  blocTest<RequestCubit, LessonDetailState>(
    'confirm conflict retains request and retry confirms',
    build: () => make(repo),
    act: (c) async {
      await c.load();
      repo.failure = const Failure('Zauzeto', statusCode: 409);
      await c.decide(RequestDecision.confirm);
      repo.failure = null;
      await c.decide(RequestDecision.confirm);
    },
    expect: () => [
      isA<LessonDetailState>().having((s) => s.isLoading, 'loading', true),
      isA<LessonDetailState>().having(
        (s) => s.lesson?.status,
        'request',
        'REQUESTED',
      ),
      isA<LessonDetailState>().having(
        (s) => s.actionInProgress,
        'saving',
        true,
      ),
      isA<LessonDetailState>()
          .having((s) => s.errorStatusCode, 'conflict', 409)
          .having((s) => s.lesson?.status, 'preserved', 'REQUESTED'),
      isA<LessonDetailState>().having((s) => s.actionInProgress, 'retry', true),
      isA<LessonDetailState>().having(
        (s) => s.lesson?.status,
        'confirmed',
        'CONFIRMED',
      ),
    ],
  );
  test('overlapping decisions and late loads cannot replace success', () async {
    final c = make(repo);
    await c.load();
    final old = Completer<Either<Failure, InstructorLesson>>();
    repo.loading = () => old.future;
    final load = c.load();
    final pending = Completer<Either<Failure, InstructorLesson>>();
    repo.deciding = () => pending.future;
    final action = c.decide(RequestDecision.reject);
    await c.decide(RequestDecision.confirm);
    expect(repo.calls, 1);
    repo.json['status'] = 'CANCELLED';
    pending.complete(Right(repo.value));
    await action;
    old.complete(const Left(Failure('Stari odgovor')));
    await load;
    expect(c.state.lesson?.status, 'CANCELLED');
    expect(c.state.errorMessage, isNull);
    await c.close();
  });
  test(
    'proposal remains requested and is cleared only by subsequent decision',
    () async {
      final c = make(repo);
      await c.load();
      await c.decide(RequestDecision.propose, startAt: DateTime(2030, 1, 1, 9));
      expect(c.state.lesson?.status, 'REQUESTED');
      expect(c.state.lesson?.proposedStartAt, DateTime(2030, 1, 1, 9));
      await c.close();
    },
  );
  testWidgets('successful confirmation removes request actions', (
    tester,
  ) async {
    final c = make(repo);
    await c.load();
    addTearDown(c.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: c, child: const RequestView()),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Potvrdi termin'), 200);
    await tester.tap(find.text('Potvrdi termin'));
    await tester.pumpAndSettle();
    expect(c.state.lesson?.status, 'CONFIRMED');
    expect(find.text('Zahtjev je obrađen.'), findsOneWidget);
    expect(find.text('Potvrdi termin'), findsNothing);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'request confirmation and rejection with recoverable failure at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = make(repo);
        await c.load();
        addTearDown(c.close);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: DrivingSchoolTheme.light(),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: BlocProvider.value(
                  value: c,
                  child: RepaintBoundary(
                    key: boundary,
                    child: ColoredBox(
                      color: DrivingSchoolTheme.light().scaffoldBackgroundColor,
                      child: const RequestView(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final directory = Platform.environment['REQUEST_SCREENSHOTS'];
        if (directory != null && scale == 1) {
          await tester.runAsync(() async {
            await Directory(directory).create(recursive: true);
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$directory/I07.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        repo.failure = const Failure('Termin je zauzet.', statusCode: 409);
        await tester.scrollUntilVisible(
          find.text('Potvrdi termin'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Potvrdi termin'));
        await tester.pumpAndSettle();
        expect(find.text('Termin je zauzet.'), findsOneWidget);
        repo.failure = null;
        await tester.ensureVisible(find.text('Odbij zahtjev'));
        await tester.tap(find.text('Odbij zahtjev'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Odbij'));
        await tester.pumpAndSettle();
        expect(c.state.lesson?.status, 'CANCELLED');
        expect(find.text('Zahtjev je obrađen.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
