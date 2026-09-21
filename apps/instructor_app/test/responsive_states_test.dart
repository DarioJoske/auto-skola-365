import 'package:auto_skola_365_instructor_app/src/features/candidates/presentation/cubit/instructor_candidates_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/presentation/cubit/instructor_candidates_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/presentation/pages/instructor_candidates_page.dart';
import 'package:auto_skola_365_instructor_app/src/features/candidates/domain/entities/instructor_candidate.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/auth/presentation/cubit/auth_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:auto_skola_365_instructor_app/src/features/schedule/presentation/pages/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthStub extends Cubit<AuthState> implements AuthCubit {
  AuthStub() : super(const AuthState(status: AuthStatus.authenticated));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ScheduleStub extends Cubit<ScheduleState> implements ScheduleCubit {
  ScheduleStub()
    : super(ScheduleState.initial().copyWith(status: ScheduleStatus.loaded));
  @override
  Future<void> selectDate(DateTime value) async {}
  @override
  Future<void> load() async {
    loadCalls++;
  }

  int loadCalls = 0;
  void fail() => emit(
    state.copyWith(
      status: ScheduleStatus.failure,
      errorMessage: 'Usluga nije dostupna.',
    ),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CandidatesStub extends Cubit<InstructorCandidatesState>
    implements InstructorCandidatesCubit {
  CandidatesStub()
    : super(
        InstructorCandidatesState.initial().copyWith(
          status: InstructorCandidatesStatus.loaded,
          candidates: [
            const InstructorCandidate(
              id: 'candidate',
              schoolId: 'school',
              firstName: 'Ana',
              lastName: 'Kandidat',
              email: 'ana@example.com',
              phone: '0911234567',
              oib: null,
              status: 'ENROLLED',
              categoryCode: 'B',
              categoryName: 'B',
              assignedInstructorId: 'instructor',
              assignedInstructorName: 'Ivan',
              notes: null,
            ),
          ],
        ),
      );
  void show(InstructorCandidatesStatus status) => emit(
    state.copyWith(
      status: status,
      errorMessage: status == InstructorCandidatesStatus.failure
          ? 'Usluga nije dostupna.'
          : null,
    ),
  );
  @override
  Future<void> load() async => show(InstructorCandidatesStatus.loading);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'instructor candidates retain search and data at $width/$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final cubit = CandidatesStub();
          addTearDown(cubit.close);
          await tester.pumpWidget(
            MaterialApp(
              theme: DrivingSchoolTheme.light(),
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: BlocProvider<InstructorCandidatesCubit>.value(
                    value: cubit,
                    child: const InstructorCandidatesView(),
                  ),
                ),
              ),
            ),
          );
          await tester.enterText(
            find.byWidgetPredicate(
              (widget) => widget is TextField && !widget.readOnly,
            ),
            'Ana',
          );
          final search = tester
              .widget<TextField>(
                find.byWidgetPredicate(
                  (widget) => widget is TextField && !widget.readOnly,
                ),
              )
              .controller!;
          FocusManager.instance.primaryFocus?.unfocus();
          for (final status in [
            InstructorCandidatesStatus.loading,
            InstructorCandidatesStatus.failure,
            InstructorCandidatesStatus.loaded,
          ]) {
            cubit.show(status);
            await tester.pump();
            await tester.scrollUntilVisible(
              find.text('Ana Kandidat'),
              250,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('Ana Kandidat'), findsOneWidget);
            expect(search.text, 'Ana');
            expect(tester.takeException(), isNull);
          }
        },
      );
      testWidgets('instructor schedule is scrollable at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = AuthStub();
        final cubit = ScheduleStub();
        addTearDown(auth.close);
        addTearDown(cubit.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: DrivingSchoolTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<AuthCubit>.value(value: auth),
                  BlocProvider<ScheduleCubit>.value(value: cubit),
                ],
                child: AppNavigationShell(
                  title: 'Autoškola 365',
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinations: const [
                    AppDestination(
                      label: 'Raspored',
                      icon: Icons.calendar_month,
                    ),
                    AppDestination(label: 'Kandidati', icon: Icons.people),
                    AppDestination(label: 'Postavke', icon: Icons.settings),
                  ],
                  child: const ScheduleView(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dnevni raspored'), findsOneWidget);
        expect(tester.takeException(), isNull);
        cubit.fail();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Pokušaj ponovno'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pokušaj ponovno'));
        expect(cubit.loadCalls, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
