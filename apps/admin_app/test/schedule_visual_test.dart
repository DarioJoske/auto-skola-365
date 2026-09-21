import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/pages/admin_shell_page.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lessons_view.dart';
import 'lesson_redesign_test.dart' show ScheduleStub;
import 'src/features/auth/auth_failure_test.dart'
    show cubitFor, SessionRepository;

void main() {
  for (final width in [1440.0, 390.0, 360.0]) {
    testWidgets('schedule and form render in the actual shell at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
      final auth = cubitFor(SessionRepository());
      await auth.login(email: 'test@example.com', password: 'test');
      final cubit = ScheduleStub();
      addTearDown(auth.close);
      addTearDown(cubit.close);
      final router = GoRouter(
        initialLocation: '/lessons',
        routes: [
          GoRoute(
            path: '/lessons',
            builder: (_, state) => const AdminShellPage(child: LessonsView()),
          ),
        ],
      );
      addTearDown(router.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<LessonsCubit>.value(value: cubit),
          ],
          child: RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: DrivingSchoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(width == 360 ? 2 : 1)),
                child: child!,
              ),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String name) async {
        if (Platform.environment['SCHEDULE_SCREENSHOTS']
            case final String output) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File(
              '$output/$name-${width.toInt()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }

      await capture('schedule');
      await tester.ensureVisible(find.text('Novi termin'));
      await tester.tap(find.text('Novi termin'));
      await tester.pumpAndSettle();
      expect(find.text('Dogovori vožnju'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('form');
      await tester.tap(find.byType(AppDropdownFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.byType(MenuItemButton), findsWidgets);
      expect(tester.takeException(), isNull);
      await capture('form-menu');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Dogovori vožnju'), findsOneWidget);
    });
  }
}
