import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_state.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lesson_dialog.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lesson_week_board.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lessons_view.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/save_lesson.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'reservation_and_candidate_test.dart' show LessonsStub;
import 'lesson_mutations_test.dart' show lessonFixture;

class ScheduleStub extends LessonsStub {
  ScheduleStub({DateTime? lessonStart}) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          from: DateTime(2030, 1, 7),
          to: DateTime(2030, 1, 14),
        ),
        lessons: [lessonFixture(startAt: lessonStart)],
      ),
    );
  }
  bool conflict = true;
  @override
  Future<void> load() async {}
  @override
  Future<void> changeRange(DateTime from, DateTime to) async => emit(
    state.copyWith(
      filters: state.filters.copyWith(from: from, to: to),
    ),
  );
  @override
  Future<void> filterInstructor(String? id) async => emit(
    state.copyWith(
      filters: state.filters.copyWith(
        instructorId: id,
        clearInstructor: id == null,
      ),
    ),
  );
  @override
  Future<void> filterStatus(String? status) async => emit(
    state.copyWith(
      filters: state.filters.copyWith(
        status: status,
        clearStatus: status == null,
      ),
    ),
  );
  @override
  Future<void> update(String id, SaveLesson lesson) async {
    saved = lesson;
    emit(state.copyWith(isSubmitting: true));
    if (conflict) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Instruktor već ima termin 10:00 – 11:00.',
          errorStatusCode: 409,
          errorEventId: state.errorEventId + 1,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isSubmitting: false,
          savedEventId: state.savedEventId + 1,
        ),
      );
    }
  }

  void refresh() => emit(state.copyWith(status: LessonsStatus.loaded));
}

void main() {
  testWidgets(
    'conflict preserves form and successful retry closes it from state',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = ScheduleStub();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: DrivingSchoolTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider<LessonsCubit>.value(
                    value: cubit,
                    child: LessonDialog(lesson: lessonFixture()),
                  ),
                ),
                child: const Text('Otvori'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Otvori'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Dogovoreno polazište',
      );
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Instruktor već ima termin 10:00 – 11:00.'),
        findsOneWidget,
      );
      expect(find.text('Dogovoreno polazište'), findsOneWidget);
      expect(cubit.saved?.endAt.difference(cubit.saved!.startAt).inMinutes, 60);
      expect(cubit.saved?.candidateId, 'Ana');
      cubit.conflict = false;
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonDialog), findsNothing);
      expect(cubit.saved?.notes, 'Dogovoreno polazište');
    },
  );
  testWidgets(
    'week navigation, instructor and final status filters survive refresh and month switch',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = ScheduleStub();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: DrivingSchoolTheme.light(),
          home: Scaffold(
            body: BlocProvider<LessonsCubit>.value(
              value: cubit,
              child: const LessonsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonWeekBoard), findsOneWidget);
      expect(find.text('Potvrđeno'), findsWidgets);
      await tester.tap(find.byTooltip('Sljedeći tjedan'));
      await tester.pumpAndSettle();
      expect(cubit.state.filters.from, DateTime(2030, 1, 14));
      await tester.tap(find.byTooltip('Filtriraj instruktora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ivan Instruktor').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dodatni prikazi i filtri'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(MenuItemButton, 'Odrađeno'),
      );
      await tester.tap(find.widgetWithText(MenuItemButton, 'Odrađeno'));
      await tester.pumpAndSettle();
      cubit.refresh();
      await tester.pumpAndSettle();
      expect(cubit.state.filters.instructorId, 'Ivan');
      expect(cubit.state.filters.status, 'COMPLETED');
      await tester.tap(find.text('Mjesec'));
      await tester.pumpAndSettle();
      cubit.refresh();
      await tester.pumpAndSettle();
      expect(
        tester.widget<SfCalendar>(find.byType(SfCalendar)).view,
        CalendarView.month,
      );
      expect(cubit.state.filters.instructorId, 'Ivan');
    },
  );
  testWidgets(
    'weekend bookings are visible without enabling the weekend filter',
    (tester) async {
      final cubit = ScheduleStub(lessonStart: DateTime(2030, 1, 12, 10));
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: DrivingSchoolTheme.light(),
          home: Scaffold(
            body: BlocProvider<LessonsCubit>.value(
              value: cubit,
              child: const LessonsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SUB · 12.'), findsOneWidget);
      await tester.ensureVisible(find.text('Ana Kandidat'));
      await tester.tap(find.text('Ana Kandidat'));
      await tester.pumpAndSettle();
      expect(find.text('Uredi'), findsOneWidget);
    },
  );
  for (final width in [360.0, 1440.0]) {
    testWidgets(
      'weekly cards expose statuses and weekend at $width with large text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final cubit = ScheduleStub();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: DrivingSchoolTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: BlocProvider<LessonsCubit>.value(
                  value: cubit,
                  child: const LessonsView(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tjedni raspored'), findsOneWidget);
        expect(find.text('Potvrđeno'), findsWidgets);
        expect(find.text('NED · 13.'), findsNothing);
        await tester.ensureVisible(find.byTooltip('Dodatni prikazi i filtri'));
        await tester.tap(find.byTooltip('Dodatni prikazi i filtri'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MenuItemButton, 'Prikaži vikend'));
        await tester.pumpAndSettle();
        expect(find.text('NED · 13.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
