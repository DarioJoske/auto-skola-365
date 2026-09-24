import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/complete_lesson_view.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/lesson_completed_view.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_365_instructor_app/src/app/app_dependencies.dart';
import 'package:auto_skola_365_instructor_app/src/app/router/app_router.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/instructor_workflow_fixture.dart';

void main() {
  late WorkflowAdapter adapter;
  late WorkflowAuth auth;
  late GoRouter router;
  final boundary = GlobalKey();
  setUp(() async {
    await getIt.reset();
    configureDependencies();
    await getIt.unregister<AuthCubit>();
    auth = WorkflowAuth();
    getIt.registerSingleton<AuthCubit>(auth);
    adapter = WorkflowAdapter();
    getIt<Dio>().httpClientAdapter = adapter;
    router = createAppRouter(authCubit: auth);
  });
  tearDown(() async {
    router.dispose();
    await auth.close();
    await getIt.reset();
  });
  Future<void> start(
    WidgetTester tester, {
    String path = '/lessons/lesson',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router.go(path);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp.router(
          theme: DrivingSchoolTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: boundary, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    } else {
      await tester.ensureVisible(target.last);
    }
    await tester.pumpAndSettle();
    await tester.tap(target.last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'detail to completion refreshes confirmation, candidate history, totals and daily agenda',
    (tester) async {
      await start(tester);
      expect(find.text('25/35 sati odrađeno'), findsOneWidget);
      await tap(tester, 'Završi sat');
      expect(find.byType(CompleteLessonView), findsOneWidget);
      expect(find.byType(AppDropdownFormField<String>), findsNothing);
      await tester.enterText(
        find.byType(TextFormField),
        '  Vježba parkiranja  ',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, 'Spremi i zaključi');
      expect(find.byType(LessonCompletedView), findsOneWidget);
      expect(find.text('Sat je evidentiran.'), findsOneWidget);
      expect(find.text('26/35 sati odrađeno'), findsOneWidget);
      expect(adapter.completions, 1);
      expect(adapter.note, 'Vježba parkiranja');
      await tap(tester, 'Profil kandidata');
      expect(find.text('26 / 35'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Interna bilješka: Vježba parkiranja'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Održano'), findsWidgets);
      expect(
        adapter.paths,
        contains(
          'GET /api/schools/school/lessons/instructor/candidates/candidate',
        ),
      );
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Dobar dan, Marko.'), findsOneWidget);
      expect(find.text('Održano'), findsWidgets);
      router.go('/lessons/lesson/complete');
      await tester.pumpAndSettle();
      expect(find.text('Ovaj je sat već evidentiran.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Spremi i zaključi'),
            )
            .onPressed,
        isNull,
      );
      expect(adapter.completions, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'direct confirmation link never claims success or writes before completion',
    (tester) async {
      await start(tester, path: '/lessons/lesson/completed');
      expect(find.text('Sat je evidentiran.'), findsNothing);
      expect(find.text('Ovaj sat nije zaključen.'), findsOneWidget);
      expect(adapter.completions, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'ongoing lesson cannot be submitted; backend rejection retains the note for retry',
    (tester) async {
      adapter.start = DateTime.now();
      await start(tester, path: '/lessons/lesson/complete');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Spremi i zaključi'),
            )
            .onPressed,
        isNull,
      );
      adapter.start = DateTime.now().subtract(const Duration(hours: 2));
      router.go('/home');
      await tester.pumpAndSettle();
      router.go('/lessons/lesson/complete');
      await tester.pumpAndSettle();
      adapter.completionStatus = 409;
      await tester.enterText(find.byType(TextFormField), 'Sačuvaj bilješku');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, 'Spremi i zaključi');
      expect(find.text('Termin nije moguće zaključiti.'), findsOneWidget);
      expect(find.text('Sačuvaj bilješku'), findsOneWidget);
      adapter.completionStatus = 200;
      adapter.progressStatus = 503;
      await tap(tester, 'Spremi i zaključi');
      expect(find.text('Sat je evidentiran.'), findsOneWidget);
      expect(find.text('Sate nije moguće učitati.'), findsOneWidget);
      expect(find.text('26/35 sati odrađeno'), findsNothing);
      adapter.progressStatus = 200;
      await tap(tester, 'Pokušaj ponovno');
      expect(find.text('26/35 sati odrađeno'), findsOneWidget);
      expect(adapter.completions, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('expired session during completion is visible and logs out', (
    tester,
  ) async {
    adapter.completionStatus = 401;
    await start(tester, path: '/lessons/lesson/complete');
    await tap(tester, 'Spremi i zaključi');
    expect(auth.logouts, 1);
    expect(
      find.text('Sesija je istekla. Prijavite se ponovno.'),
      findsOneWidget,
    );
    expect(adapter.status, 'CONFIRMED');
    await tester.pumpWidget(const SizedBox());
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('I01–I06 and I11 render without overflow at 390/$scale', (
      tester,
    ) async {
      final output = Platform.environment['INSTRUCTOR_SCREENSHOTS'];
      if (output != null && scale == 1) {
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
      }
      await start(tester, path: '/home', scale: scale);
      for (final entry in {
        'I01': '/home',
        'I02': '/',
        'I03': '/lessons/lesson',
        'I04': '/lessons/lesson/complete',
        'I05': '/candidates',
        'I06': '/candidates/candidate',
        'I11': '/lessons/lesson/completed',
      }.entries) {
        if (entry.key == 'I11') adapter.status = 'COMPLETED';
        router.go(entry.value);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        if (output != null && scale == 1) {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$output/${entry.key}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
