import 'src/features/auth/auth_failure_test.dart'
    show SessionRepository, cubitFor;
import 'package:auto_skola_365_admin_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_admin_app/src/core/api/failure.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/cubit/school_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/cubit/school_overview_state.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/pages/overview_view.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructor_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructor_overview_state.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/pages/instructor_overview_view.dart';
import 'overview_cubit_test.dart' show schoolData, instructorData;

class SchoolStub extends Cubit<SchoolOverviewState>
    implements SchoolOverviewCubit {
  SchoolStub() : super(SchoolOverviewState(data: schoolData()));
  int loads = 0;
  void show(SchoolOverviewState state) => emit(state);
  @override
  Future<void> load() async {
    loads++;
  }
}

class InstructorStub extends Cubit<InstructorOverviewState>
    implements InstructorOverviewCubit {
  InstructorStub() : super(InstructorOverviewState(data: instructorData()));
  int loads = 0;
  String? query;
  void show(InstructorOverviewState state) => emit(state);
  @override
  Future<void> load() async {
    loads++;
  }

  @override
  Future<void> search(String query, bool? active) async {
    this.query = query;
  }
}

Widget harness(Widget child, {double scale = 1}) => MaterialApp(
  theme: DrivingSchoolTheme.light(),
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);
void main() {
  for (final page in ['school', 'instructors']) {
    testWidgets('$page session expiry is visible and logs out once', (
      tester,
    ) async {
      final repository = SessionRepository();
      final auth = cubitFor(repository);
      final school = SchoolStub();
      final instructors = InstructorStub();
      addTearDown(auth.close);
      addTearDown(school.close);
      addTearDown(instructors.close);
      await tester.pumpWidget(
        harness(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<SchoolOverviewCubit>.value(value: school),
              BlocProvider<InstructorOverviewCubit>.value(value: instructors),
            ],
            child: page == 'school'
                ? const OverviewView()
                : const InstructorOverviewView(),
          ),
        ),
      );
      if (page == 'school') {
        school.show(
          const SchoolOverviewState(
            failure: Failure('Isteklo', statusCode: 401),
            errorEventId: 1,
          ),
        );
      } else {
        instructors.show(
          const InstructorOverviewState(
            failure: Failure('Isteklo', statusCode: 401),
            errorEventId: 1,
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(
        find.text('Sesija je istekla. Prijavite se ponovno.'),
        findsOneWidget,
      );
      expect(repository.cleared, 1);
    });
  }
  for (final width in [390.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('dashboard data and retry at $width/$scale', (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final cubit = SchoolStub();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          harness(
            BlocProvider<SchoolOverviewCubit>.value(
              value: cubit,
              child: const OverviewView(),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pregled škole'), findsOneWidget);
        expect(find.text('Aktivni kandidati'), findsOneWidget);
        expect(tester.takeException(), isNull);
        cubit.show(
          SchoolOverviewState(
            data: schoolData(),
            failure: const Failure('Greška pregleda'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Greška pregleda'), findsOneWidget);
        await tester.tap(find.text('Pokušaj ponovno'));
        expect(cubit.loads, 1);
        await tester.scrollUntilVisible(find.text('Aktivni kandidati'), 200);
        expect(find.text('Aktivni kandidati'), findsOneWidget);
      });
      testWidgets('instructor search and empty/error state at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final cubit = InstructorStub();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          harness(
            BlocProvider<InstructorOverviewCubit>.value(
              value: cubit,
              child: const InstructorOverviewView(),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Ivan Ivić'), findsOneWidget);
        expect(find.text('2 h 0 min\n2 termina'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Ivan');
        await tester.tap(find.text('Pretraži'));
        expect(cubit.query, 'Ivan');
        expect(tester.takeException(), isNull);
        cubit.show(InstructorOverviewState(data: instructorData(empty: true)));
        await tester.pumpAndSettle();
        expect(find.text('Nema instruktora'), findsOneWidget);
        cubit.show(
          const InstructorOverviewState(failure: Failure('Nema pristupa')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nema pristupa'), findsOneWidget);
        await tester.tap(find.text('Pokušaj ponovno'));
        expect(cubit.loads, 1);
      });
    }
  }
  testWidgets(
    'assigned candidate dialog opens and navigates to filtered candidates',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = InstructorStub();
      addTearDown(cubit.close);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: BlocProvider<InstructorOverviewCubit>.value(
                value: cubit,
                child: const InstructorOverviewView(),
              ),
            ),
          ),
          GoRoute(
            path: '/candidates',
            builder: (_, state) => Scaffold(
              body: Text(
                '${state.uri.queryParameters['query']} / ${state.uri.queryParameters['instructorId']}',
              ),
            ),
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
      await tester.tap(find.text('1 dodijeljenih'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Anić'), findsOneWidget);
      await tester.tap(find.text('Ana Anić'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Anić / i'), findsOneWidget);
    },
  );
}
