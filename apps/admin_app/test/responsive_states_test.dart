import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lessons_page.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_state.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/pages/candidates_page.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructors_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructors_state.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/pages/instructors_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'reservation_and_candidate_test.dart'
    show CandidatesStub, LessonsStub, candidate, instructor;

class RefreshCandidates extends CandidatesStub {
  int loads = 0;
  void show(CandidatesStatus status) => emit(
    state.copyWith(
      status: status,
      candidates: [candidate('Ana', 'Ivan')],
      errorMessage: status == CandidatesStatus.failure
          ? 'Usluga nije dostupna.'
          : null,
    ),
  );
  @override
  Future<void> load() async {
    loads++;
    show(CandidatesStatus.loading);
  }
}

class RefreshInstructors extends Cubit<InstructorsState>
    implements InstructorsCubit {
  RefreshInstructors()
    : super(
        InstructorsState(
          status: InstructorsStatus.loaded,
          instructors: [instructor('Ivan')],
        ),
      );
  void show(InstructorsStatus status) => emit(
    state.copyWith(
      status: status,
      errorMessage: status == InstructorsStatus.failure
          ? 'Usluga nije dostupna.'
          : null,
    ),
  );
  @override
  Future<void> load() async => show(InstructorsStatus.loading);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CalendarStub extends LessonsStub {
  @override
  Future<void> changeRange(DateTime from, DateTime to) async {}
}

Widget harness(Widget child, double scale) => MaterialApp(
  theme: DrivingSchoolTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: AppNavigationShell(
      mode: AppNavigationMode.admin,
      title: 'Autoškola 365',
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: const [
        AppDestination(label: 'Pregled', icon: Icons.home),
        AppDestination(label: 'Kandidati', icon: Icons.people),
      ],
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);
void main() {
  for (final width in [1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'admin candidates preserve search and results at $width/$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final cubit = RefreshCandidates()..show(CandidatesStatus.loaded);
          addTearDown(cubit.close);
          await tester.pumpWidget(
            harness(
              BlocProvider<CandidatesCubit>.value(
                value: cubit,
                child: const CandidatesView(),
              ),
              scale,
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, 'Ana');
          final search = tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!;
          FocusManager.instance.primaryFocus?.unfocus();
          for (final status in [
            CandidatesStatus.loading,
            CandidatesStatus.failure,
            CandidatesStatus.loaded,
          ]) {
            cubit.show(status);
            await tester.pump();
            await tester.scrollUntilVisible(
              find.text('Ana Kandidat'),
              200,
              scrollable: find
                  .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pump();
            expect(find.text('Ana Kandidat'), findsOneWidget);
            expect(search.text, 'Ana');
            expect(tester.takeException(), isNull);
            if (status == CandidatesStatus.failure) {
              await tester.scrollUntilVisible(
                find.text('Pokušaj ponovno'),
                -200,
                scrollable: find
                    .descendant(
                      of: find.byType(CustomScrollView),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await tester.pump();
              await tester.tap(find.text('Pokušaj ponovno'));
              await tester.pump();
              expect(cubit.loads, 1);
            }
          }
        },
      );
      testWidgets('admin calendar fits $width/$scale', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final cubit = CalendarStub();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          harness(
            BlocProvider<LessonsCubit>.value(
              value: cubit,
              child: const LessonsView(),
            ),
            scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
      testWidgets('admin instructors retain results at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final cubit = RefreshInstructors();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          harness(
            BlocProvider<InstructorsCubit>.value(
              value: cubit,
              child: const InstructorsView(),
            ),
            scale,
          ),
        );
        for (final status in [
          InstructorsStatus.loading,
          InstructorsStatus.failure,
          InstructorsStatus.loaded,
        ]) {
          cubit.show(status);
          await tester.pump();
          expect(find.text('Ivan Instruktor'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
