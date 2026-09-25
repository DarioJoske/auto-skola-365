import 'package:auto_skola_365_candidate_app/src/features/portal/domain/usecases/respond_proposal.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_365_candidate_app/src/core/api/failure.dart';
import 'package:auto_skola_365_candidate_app/src/core/api/result.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/entities/candidate_portal.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/repositories/portal_repository.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/usecases/load_portal.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/domain/usecases/request_lesson.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/cubit/portal_cubit.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/pages/home_page.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/pages/lessons_page.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/cubit/portal_state.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/widgets/request_lesson_dialog.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

CandidateLesson lesson(String id, String status, DateTime date) =>
    CandidateLesson(
      id: id,
      status: status,
      startAt: date,
      endAt: date.add(const Duration(hours: 1)),
      instructorName: 'Ivan Horvat',
    );
CandidatePortal portal({
  int count = 25,
  bool canRequest = true,
  List<CandidateLesson>? lessons,
}) => CandidatePortal(
  candidateId: 'candidate',
  firstName: 'Ana',
  lastName: 'Anić',
  schoolName: 'Autoškola Zagreb',
  categoryCode: 'B',
  instructorName: 'Ivan Horvat',
  canRequestLesson: canRequest,
  completedDrivingHours: count,
  requiredDrivingHours: 35,
  lessons:
      lessons ??
      [
        lesson(
          'upcoming',
          'CONFIRMED',
          DateTime.now().add(const Duration(days: 1)),
        ),
        lesson(
          'past',
          'COMPLETED',
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
);

class PortalFake extends Fake implements PortalRepository {
  CandidatePortal value = portal();
  FutureEither<CandidatePortal> Function()? onLoad;
  FutureEither<void> Function()? onRequest;
  int calls = 0;
  @override
  FutureEither<CandidatePortal> load({
    required String schoolId,
    required String accessToken,
  }) => onLoad?.call() ?? Future.value(Right(value));
  @override
  FutureEither<void> requestLesson({
    required String schoolId,
    required String accessToken,
    required DateTime startAt,
    String? notes,
  }) {
    calls++;
    return onRequest?.call() ?? Future.value(const Right(null));
  }
}

PortalCubit cubitFor(PortalFake repository) => PortalCubit(
  loadPortal: LoadPortal(repository),
  requestLesson: RequestLesson(repository),
  respondProposal: RespondProposal(repository),
  schoolId: 'school',
  accessToken: 'token',
);
Widget app(PortalCubit cubit, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: DrivingSchoolTheme.light(),
  locale: const Locale('hr'),
  supportedLocales: const [Locale('hr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(
    body: BlocProvider.value(value: cubit, child: child),
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('packages/auto_skola_design_system/SchoolSans')
      ..addFont(
        rootBundle.load(
          'packages/auto_skola_design_system/assets/fonts/Roboto-Regular.ttf',
        ),
      )
      ..addFont(
        rootBundle.load(
          'packages/auto_skola_design_system/assets/fonts/Roboto-Bold.ttf',
        ),
      );
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late PortalFake repository;
  setUp(() => repository = PortalFake());
  test('initial state contains no fabricated data', () async {
    final c = cubitFor(repository);
    expect(c.state.data, isNull);
    expect(c.state.loading, false);
    expect(c.state.saving, false);
    await c.close();
  });
  blocTest<PortalCubit, PortalState>(
    'loads actual candidate hours',
    build: () => cubitFor(repository),
    act: (c) => c.load(),
    expect: () => [
      isA<PortalState>().having((s) => s.loading, 'loading', true),
      isA<PortalState>().having(
        (s) => s.data?.completedDrivingHours,
        'hours',
        25,
      ),
    ],
  );
  blocTest<PortalCubit, PortalState>(
    'refresh failure preserves data and retry succeeds',
    build: () => cubitFor(repository),
    act: (c) async {
      await c.load();
      repository.onLoad = () async =>
          const Left(Failure('Nema veze.', statusCode: 503));
      await c.load();
      repository.onLoad = null;
      repository.value = portal(count: 26);
      await c.load();
    },
    expect: () => [
      isA<PortalState>(),
      isA<PortalState>(),
      isA<PortalState>(),
      isA<PortalState>()
          .having((s) => s.loadFailure?.statusCode, 'failure', 503)
          .having((s) => s.data?.completedDrivingHours, 'preserved', 25),
      isA<PortalState>(),
      isA<PortalState>().having(
        (s) => s.data?.completedDrivingHours,
        'updated',
        26,
      ),
    ],
  );
  blocTest<PortalCubit, PortalState>(
    'request conflict preserves data then retry refreshes portal',
    build: () => cubitFor(repository),
    act: (c) async {
      await c.load();
      repository.onRequest = () async =>
          const Left(Failure('Termin je zauzet.', statusCode: 409));
      await c.requestLesson(DateTime.now().add(const Duration(days: 1)), null);
      repository.onRequest = null;
      await c.requestLesson(DateTime.now().add(const Duration(days: 1)), null);
    },
    expect: () => [
      isA<PortalState>(),
      isA<PortalState>(),
      isA<PortalState>().having((s) => s.saving, 'saving', true),
      isA<PortalState>().having(
        (s) => s.actionFailure?.statusCode,
        'conflict',
        409,
      ),
      isA<PortalState>().having((s) => s.saving, 'retry', true),
      isA<PortalState>().having((s) => s.savedId, 'saved event', 1),
      isA<PortalState>().having((s) => s.loading, 'refresh', true),
      isA<PortalState>(),
    ],
  );
  test(
    'late refresh cannot overwrite newer data or post to closed cubit',
    () async {
      final first = Completer<Either<Failure, CandidatePortal>>();
      final second = Completer<Either<Failure, CandidatePortal>>();
      final queue = [first, second];
      repository.onLoad = () => queue.removeAt(0).future;
      final c = cubitFor(repository);
      final a = c.load();
      final b = c.load();
      second.complete(Right(portal(count: 30)));
      await b;
      first.complete(Right(portal(count: 20)));
      await a;
      expect(c.state.data?.completedDrivingHours, 30);
      final pending = Completer<Either<Failure, CandidatePortal>>();
      repository.onLoad = () => pending.future;
      final load = c.load();
      await c.close();
      pending.complete(Right(portal()));
      await load;
    },
  );
  test(
    'duplicate requests are suppressed and 401 clears protected data',
    () async {
      final pending = Completer<Either<Failure, void>>();
      repository.onRequest = () => pending.future;
      final c = cubitFor(repository);
      await c.load();
      final save = c.requestLesson(
        DateTime.now().add(const Duration(days: 1)),
        null,
      );
      await c.requestLesson(DateTime.now().add(const Duration(days: 1)), null);
      expect(repository.calls, 1);
      pending.complete(const Right(null));
      await save;
      repository.onLoad = () async =>
          const Left(Failure('Sesija je istekla.', statusCode: 401));
      await c.load();
      expect(c.state.data, isNull);
      await c.close();
    },
  );
  test('requests need an assigned instructor and future date', () async {
    final c = cubitFor(repository);
    await c.load();
    await c.requestLesson(DateTime(2020), null);
    expect(repository.calls, 0);
    expect(c.state.actionFailure, isNotNull);
    repository.value = portal(canRequest: false);
    await c.load();
    await c.requestLesson(DateTime(2030), null);
    expect(repository.calls, 0);
    await c.close();
  });
  test(
    'upcoming excludes cancelled and completed, history is newest first',
    () {
      final now = DateTime(2030, 1, 1);
      final data = portal(
        lessons: [
          lesson('later', 'CONFIRMED', now.add(const Duration(days: 2))),
          lesson('next', 'REQUESTED', now.add(const Duration(days: 1))),
          lesson('cancelled', 'CANCELLED', now.add(const Duration(days: 3))),
          lesson('past', 'COMPLETED', now.subtract(const Duration(days: 1))),
        ],
      );
      expect(data.upcomingAt(now).map((l) => l.id), ['next', 'later']);
      expect(data.historyAt(now).map((l) => l.id), ['cancelled', 'past']);
    },
  );
  for (final width in [390.0, 1200.0]) {
    testWidgets('dashboard fits width $width and shows real hours', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = cubitFor(repository);
      await c.load();
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: app(c, const HomePage())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bok, Ana.'), findsOneWidget);
      expect(find.text('25/35 sati odrađeno'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 390) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${Directory.systemTemp.path}/auto-skola-candidate-mobile.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });
  }
  testWidgets('request form keeps conflict visible then closes after success', (
    tester,
  ) async {
    final c = cubitFor(repository);
    await c.load();
    repository.onRequest = () async =>
        const Left(Failure('Termin je zauzet.', statusCode: 409));
    await tester.pumpWidget(
      app(
        c,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showLessonRequest(context),
            child: const Text('Otvori'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pošalji zahtjev'));
    await tester.pumpAndSettle();
    expect(find.text('Termin je zauzet.'), findsOneWidget);
    expect(find.byType(RequestLessonDialog), findsOneWidget);
    repository.onRequest = null;
    await tester.tap(find.text('Pošalji zahtjev'));
    await tester.pumpAndSettle();
    expect(find.byType(RequestLessonDialog), findsNothing);
    expect(
      find.text('Zahtjev je poslan. Čeka potvrdu instruktora.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
  testWidgets('lesson tabs separate upcoming from history', (tester) async {
    final c = cubitFor(repository);
    await c.load();
    await tester.pumpWidget(app(c, const LessonsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Potvrđeno'), findsOneWidget);
    expect(find.text('Odrađeno'), findsNothing);
    await tester.tap(find.text('Povijest'));
    await tester.pumpAndSettle();
    expect(find.text('Odrađeno'), findsOneWidget);
    expect(find.text('Potvrđeno'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
}
