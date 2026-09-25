import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_365_candidate_app/src/core/api/result.dart';
import 'package:auto_skola_365_candidate_app/src/core/api/failure.dart';
import 'package:auto_skola_365_candidate_app/src/app/app_dependencies.dart';
import 'package:auto_skola_365_candidate_app/src/app/candidate_app.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/entities/auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/bootstrap_auth_session.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/login.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/domain/usecases/logout.dart';
import 'package:auto_skola_365_candidate_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/cubit/portal_cubit.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/cubit/portal_state.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/pages/request_sent_page.dart';
import 'package:auto_skola_365_candidate_app/src/features/portal/presentation/pages/lessons_page.dart';
import 'package:dio/dio.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'portal_test.dart' show PortalFake, cubitFor;
import 'auth_test.dart' show Remote;
import 'navigation_test.dart' show SessionRepository;

class ResponseFake extends PortalFake {
  FutureEither<void> Function()? responding;
  int responses = 0;
  @override
  FutureEither<void> respondProposal({
    required String schoolId,
    required String accessToken,
    required String lessonId,
    required DateTime startAt,
    required bool accept,
  }) {
    responses++;
    return responding?.call() ?? Future.value(const Right(null));
  }
}

class RequestAdapter implements HttpClientAdapter {
  String? status;
  DateTime start = DateTime(2030, 1, 1, 9);
  DateTime? proposed;
  bool fail = false;
  int requests = 0, responses = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path.endsWith('/reservations')) {
      requests++;
      if (fail) {
        return json({
          'status': 409,
          'code': 'CONFLICT',
          'message': 'Odabrani termin je zauzet.',
          'path': options.path,
        }, 409);
      }
      start = DateTime.parse(options.data['startAt'] as String);
      status = 'REQUESTED';
      return json({'id': 'lesson'}, 201);
    }
    if (options.path.endsWith('/proposal-response')) {
      responses++;
      if (fail) {
        return json({
          'status': 409,
          'code': 'CONFLICT',
          'message': 'Prijedlog više nije dostupan.',
          'path': options.path,
        }, 409);
      }
      status = options.data['accept'] == true ? 'CONFIRMED' : 'CANCELLED';
      start = proposed!;
      proposed = null;
      return json(null, 204);
    }
    return json({
      'candidateId': 'candidate',
      'firstName': 'Ana',
      'lastName': 'Horvat',
      'schoolName': 'Autoškola 365',
      'categoryCode': 'B',
      'instructorName': 'Marko Babić',
      'canRequestLesson': true,
      'completedDrivingHours': 25,
      'requiredDrivingHours': 35,
      'lessons': [
        if (status != null)
          {
            'id': 'lesson',
            'status': status,
            'startAt': start.toIso8601String(),
            'endAt': start.add(const Duration(hours: 1)).toIso8601String(),
            'instructorName': 'Marko Babić',
            'branchName': null,
            'proposedStartAt': proposed?.toIso8601String(),
          },
      ],
    }, 200);
  }

  ResponseBody json(Object? data, int code) => ResponseBody.fromString(
    jsonEncode(data),
    code,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

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

  blocTest<PortalCubit, PortalState>(
    'response conflict retains data and retry refreshes portal',
    build: () => cubitFor(
      ResponseFake()
        ..responding = () async =>
            const Left(Failure('Zauzeto', statusCode: 409)),
    ),
    act: (c) async {
      await c.load();
      await c.respondProposal('lesson', DateTime(2030), true);
    },
    expect: () => [
      isA<PortalState>().having((s) => s.loading, 'loading', true),
      isA<PortalState>().having((s) => s.data != null, 'loaded', true),
      isA<PortalState>().having((s) => s.saving, 'saving', true),
      isA<PortalState>()
          .having((s) => s.actionFailure?.statusCode, 'conflict', 409)
          .having((s) => s.data != null, 'preserved', true),
    ],
  );
  test(
    'duplicate answers are suppressed and success survives refresh failure',
    () async {
      final repo = ResponseFake();
      final c = cubitFor(repo);
      await c.load();
      final pending = Completer<Either<Failure, void>>();
      repo.responding = () => pending.future;
      final response = c.respondProposal('lesson', DateTime(2030), true);
      await c.respondProposal('lesson', DateTime(2030), false);
      expect(repo.responses, 1);
      repo.onLoad = () async =>
          const Left(Failure('Osvježavanje nije uspjelo.', statusCode: 503));
      pending.complete(const Right(null));
      await response;
      expect(c.state.responseId, 1);
      expect(c.state.loadFailure?.statusCode, 503);
      expect(c.state.data, isNotNull);
      await c.close();
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'C04 C05 and candidate proposal acceptance use real router and Dio at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await getIt.reset();
        configureDependencies();
        await getIt.unregister<AuthCubit>();
        final user = (await Remote().login(
          email: 'ana@example.com',
          password: 'test',
        )).user.toEntity();
        final repo = SessionRepository(
          AuthSession(
            accessToken: 'token',
            user: user,
            candidateMembership: user.candidateMembership!,
          ),
        );
        final auth = AuthCubit(
          bootstrapAuthSession: BootstrapAuthSession(repo),
          login: Login(repo),
          logout: Logout(repo),
        );
        getIt.registerSingleton<AuthCubit>(auth);
        final adapter = RequestAdapter();
        getIt<Dio>().httpClientAdapter = adapter;
        final boundary = GlobalKey();
        addTearDown(() async {
          await getIt.reset();
          await auth.close();
        });
        await tester.pumpWidget(
          RepaintBoundary(key: boundary, child: const CandidateApp()),
        );
        await tester.pumpAndSettle();
        await auth.login(email: 'ana@example.com', password: 'test');
        await tester.pumpAndSettle();
        final homeContext = tester.element(find.text('Bok, Ana.'));
        GoRouter.of(homeContext).go('/lessons/request-sent');
        await tester.pumpAndSettle();
        expect(find.text('Pregled zahtjeva'), findsOneWidget);
        expect(adapter.requests, 0);
        GoRouter.of(
          tester.element(find.byType(RequestSentPage)),
        ).go('/lessons/request');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('request-note')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('request-note')),
          'Odgovara mi i kasnije.',
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        if (scale == 1) await capture(tester, boundary, 'C04');
        adapter.fail = true;
        await tap(tester, 'Pošalji zahtjev');
        expect(find.text('Odabrani termin je zauzet.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('request-note')),
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('request-note')))
              .controller!
              .text,
          'Odgovara mi i kasnije.',
        );
        adapter.fail = false;
        await tap(tester, 'Pošalji zahtjev');
        expect(find.text('Zahtjev je poslan'), findsOneWidget);
        expect(adapter.status, 'REQUESTED');
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        if (scale == 1) await capture(tester, boundary, 'C05');
        adapter.proposed = DateTime.now().add(const Duration(days: 3));
        final c = tester
            .element(find.byType(RequestSentPage))
            .read<PortalCubit>();
        unawaited(c.load());
        await tester.pumpAndSettle();
        await tap(tester, 'Povratak na termine');
        adapter.fail = true;
        await tap(tester, 'Prihvati prijedlog');
        expect(find.text('Prijedlog više nije dostupan.'), findsOneWidget);
        expect(adapter.status, 'REQUESTED');
        adapter.fail = false;
        await tap(tester, 'Prihvati prijedlog');
        expect(adapter.status, 'CONFIRMED');
        expect(c.state.data?.completedDrivingHours, 25);
        expect(find.text('Prihvati prijedlog'), findsNothing);
        expect(tester.takeException(), isNull);
        GoRouter.of(
          tester.element(find.byType(LessonsPage)),
        ).go('/lessons/request');
        await tester.pumpAndSettle();
        await tap(tester, 'Pošalji zahtjev');
        adapter.proposed = DateTime.now().add(const Duration(days: 4));
        unawaited(c.load());
        await tester.pumpAndSettle();
        await tap(tester, 'Povratak na termine');
        await tap(tester, 'Odbij prijedlog');
        expect(adapter.status, 'CANCELLED');
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

Future<void> tap(WidgetTester tester, String text) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  final finder = find.text(text);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['REQUEST_SCREENSHOTS'];
  if (directory == null) return;
  await tester.runAsync(() async {
    await Directory(directory).create(recursive: true);
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
