import 'package:auto_skola_365_admin_app/src/app/router/planned_routes.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('every planned deep link renders an honest placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) => const Scaffold(body: Text('Početna')),
        ),
        ...plannedRoutes(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: DrivingSchoolTheme.light(),
        routerConfig: router,
        builder: (context, child) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final screen in plannedScreens) {
      router.go(screen.path.replaceAll(RegExp(r':[^/]+'), 'example-id'));
      await tester.pumpAndSettle();
      expect(find.text(screen.title), findsOneWidget);
      expect(find.text('U pripremi'), findsOneWidget);
      expect(find.text(screen.description), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Svi ekrani'), findsNothing);
    }
  });
}
