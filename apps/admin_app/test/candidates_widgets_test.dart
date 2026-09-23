import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/core/api/result.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/widgets/candidate_form.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/widgets/candidates_table.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/pages/candidate_profile_view.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/pages/candidates_view.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/pages/candidate_enrollment_page.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_cubit.dart';
import 'candidates_redesign_test.dart';
import 'overview_schedule_test.dart' show ScheduleRepository;
import 'lesson_mutations_test.dart' show lessonFixture;

Widget formHarness(
  CandidatesCubit cubit, {
  bool editing = false,
  ValueChanged<dynamic>? onSaved,
}) => MaterialApp(
  theme: DrivingSchoolTheme.light(),
  home: Scaffold(
    body: BlocProvider.value(
      value: cubit,
      child: SingleChildScrollView(
        child: CandidateForm(
          candidate: editing ? candidateFixture() : null,
          onSaved: onSaved ?? (_) {},
          onCancel: () {},
        ),
      ),
    ),
  ),
);
Future<void> tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Spremi'));
  await tester.tap(find.text('Spremi'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'form validates, preserves data after failure and saves the retry',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = CandidateRepositoryFake();
      final cubit = candidatesCubit(repo);
      addTearDown(cubit.close);
      var saved = 0;
      await tester.pumpWidget(formHarness(cubit, onSaved: (_) => saved++));
      await tapSave(tester);
      expect(find.text('Obavezno polje.'), findsNWidgets(2));
      expect(repo.saves, 0);
      await tester.enterText(find.widgetWithText(TextFormField, 'Ime'), 'Ana');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Prezime'),
        'Horvat',
      );
      final hours = find.widgetWithText(
        TextFormField,
        'Potreban broj sati vožnje',
      );
      await tester.enterText(hours, '0');
      await tapSave(tester);
      expect(repo.saves, 0);
      expect(find.text('Unesite pozitivan cijeli broj.'), findsOneWidget);
      await tester.enterText(hours, '40');
      repo.saveFailure = const Failure(
        'Kandidat već postoji.',
        statusCode: 409,
      );
      await tapSave(tester);
      expect(saved, 0);
      expect(tester.widget<TextFormField>(hours).controller!.text, '40');
      expect(find.text('Kandidat već postoji.'), findsNWidgets(2));
      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Ime'))
            .controller!
            .text,
        'Ana',
      );
      repo.saveFailure = null;
      await tapSave(tester);
      expect(saved, 1);
      expect(repo.created?.requiredDrivingHours, 40);
      expect(repo.created?.loginPassword, isNull);
    },
  );
  testWidgets(
    'password activation requires email and editing keeps login email separate',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = CandidateRepositoryFake();
      final cubit = candidatesCubit(repo);
      addTearDown(cubit.close);
      await tester.pumpWidget(formHarness(cubit));
      await tester.enterText(find.widgetWithText(TextFormField, 'Ime'), 'Ana');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Prezime'),
        'Horvat',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Lozinka za kandidatsku aplikaciju (neobavezno)',
        ),
        'InitialPass123',
      );
      await tapSave(tester);
      expect(repo.saves, 0);
      expect(
        find.text('Za aktivaciju pristupa unesite e-mail.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kontaktni e-mail'),
        'invalid',
      );
      await tapSave(tester);
      expect(repo.saves, 0);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kontaktni e-mail'),
        'novi@example.com',
      );
      await tapSave(tester);
      expect(repo.created?.loginPassword, 'InitialPass123');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(formHarness(cubit, editing: true));
      expect(
        find.text('Email za prijavu: prijava@example.com'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kontaktni e-mail'),
        'drugi@example.com',
      );
      await tapSave(tester);
      expect(repo.updated?.email, 'drugi@example.com');
      expect(repo.updated?.loginPassword, isNull);
    },
  );
  testWidgets(
    'table paginates, scrolls horizontally and opens candidate profile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: CandidatesTable(
                  candidates: List.generate(
                    11,
                    (i) => candidateFixture(id: 'Kandidat $i'),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/candidates/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Profil ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: DrivingSchoolTheme.light(),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kandidat 10 Horvat'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Sljedeća stranica'));
      await tester.tap(find.byTooltip('Sljedeća stranica'));
      await tester.pumpAndSettle();
      expect(find.text('Kandidat 10 Horvat'), findsOneWidget);
      await tester.drag(
        find.byType(AppHorizontalScroll),
        const Offset(-650, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(AppHorizontalScroll), const Offset(650, 0));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kandidat 10 Horvat'));
      await tester.tap(find.text('Kandidat 10 Horvat'));
      await tester.pumpAndSettle();
      expect(find.text('Profil Kandidat 10'), findsOneWidget);
    },
  );
  for (final width in [390.0, 1440.0]) {
    for (final screen in ['list', 'profile', 'enrollment']) {
      testWidgets(
        '$screen layout at $width with real totals and unavailable modules',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
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
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          final repo = CandidateRepositoryFake();
          final cubit = candidatesCubit(repo);
          await cubit.load();
          addTearDown(cubit.close);
          final history = ScheduleRepository();
          final profile = profileCubit(repo, history);
          addTearDown(profile.close);
          final load = profile.load();
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          history.requests.single.complete(
            success([lessonFixture(status: 'COMPLETED')]),
          );
          await load;
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: DrivingSchoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(width == 390 ? 2 : 1)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: boundary,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: cubit),
                    BlocProvider.value(value: profile),
                  ],
                  child: AppNavigationShell(
                    mode: AppNavigationMode.admin,
                    title: 'autoškola 365',
                    subtitle: 'Sintetički testni podaci',
                    selectedIndex: 2,
                    onDestinationSelected: (_) {},
                    destinations: const [
                      AppDestination(
                        label: 'Pregled',
                        icon: Icons.dashboard_outlined,
                      ),
                      AppDestination(
                        label: 'Raspored',
                        icon: Icons.calendar_month_outlined,
                      ),
                      AppDestination(
                        label: 'Kandidati',
                        icon: Icons.groups_outlined,
                      ),
                      AppDestination(
                        label: 'Instruktori',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: screen == 'list'
                          ? const CandidatesView()
                          : screen == 'profile'
                          ? const CandidateProfileView()
                          : const CandidateEnrollmentPage(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (Platform.environment['CANDIDATE_SCREENSHOTS']
              case final String output) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(output).create(recursive: true);
              await File(
                '$output/$screen-${width.toInt()}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (screen == 'profile') {
            expect(find.text('37 / 35'), findsOneWidget);
            expect(
              find.text('Kontaktni e-mail: kontakt@example.com'),
              findsOneWidget,
            );
            expect(
              find.text('E-mail za prijavu: prijava@example.com'),
              findsOneWidget,
            );
            for (final module in ['Dokumenti', 'Uplate', 'Poruke']) {
              await tester.scrollUntilVisible(
                find.text(module),
                250,
                scrollable: find
                    .descendant(
                      of: find.byType(ListView).first,
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await tester.tap(find.text(module));
              await tester.pumpAndSettle();
              expect(find.text('$module nisu dostupni'), findsOneWidget);
            }
          }
        },
      );
    }
  }
}
