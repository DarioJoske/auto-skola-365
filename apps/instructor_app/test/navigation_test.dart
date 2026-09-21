import 'package:auto_skola_365_instructor_app/src/app/router/planned_routes.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/shell/presentation/pages/instructor_shell_page.dart';
import 'package:auto_skola_365_instructor_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'responsive_states_test.dart' show AuthStub;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'five Figma destinations navigate through the bottom bar at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = AuthStub();
        addTearDown(auth.close);
        final router = GoRouter(
          routes: [
            ShellRoute(
              builder: (_, state, child) => InstructorShellPage(child: child),
              routes: [
                ...plannedRoutes(),
                GoRoute(
                  path: '/',
                  builder: (_, state) => const Text('Moj raspored'),
                ),
                GoRoute(
                  path: '/candidates',
                  builder: (_, state) => const Text('Moji kandidati'),
                ),
                GoRoute(
                  path: '/profile',
                  builder: (_, state) => const SettingsPage(),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
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
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final entry in {
          'Danas': '/home',
          'Raspored': '/',
          'Kandidati': '/candidates',
          'Poruke': '/messages',
          'Profil': '/profile',
        }.entries) {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(entry.key),
            ),
          );
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, entry.value);
          if (entry.key == 'Danas' || entry.key == 'Poruke') {
            expect(find.text('U pripremi'), findsOneWidget);
          }
          if (entry.key == 'Profil') {
            expect(find.text('Moj profil'), findsOneWidget);
          }
          expect(find.byTooltip('Svi ekrani'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
