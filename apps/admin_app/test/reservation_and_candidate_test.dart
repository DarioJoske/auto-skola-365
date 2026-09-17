import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/domain/entities/update_candidate.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/data/models/update_candidate_model.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/cubit/candidates_state.dart';
import 'package:auto_skola_365_admin_app/src/features/candidates/presentation/pages/candidate_dialog.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/domain/entities/instructor.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/domain/entities/save_lesson.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/cubit/lessons_state.dart';
import 'package:auto_skola_365_admin_app/src/features/lessons/presentation/pages/lesson_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'progress_test.dart' show HoursRepository, hoursCubit;

Candidate candidate(String id, String? instructor, {bool hasLogin = false}) =>
    Candidate(
      id: id,
      schoolId: 'school',
      firstName: id,
      lastName: 'Kandidat',
      email: null,
      phone: null,
      oib: null,
      status: 'ENROLLED',
      categoryCode: 'B',
      categoryName: 'B',
      assignedInstructorId: instructor,
      assignedInstructorName: instructor,
      notes: null,
      requiredDrivingHours: 35,
      hasLogin: hasLogin,
      loginEmail: hasLogin ? 'login@example.com' : null,
    );
Instructor instructor(String id) => Instructor(
  id: id,
  schoolId: 'school',
  userId: id,
  membershipId: id,
  firstName: id,
  lastName: 'Instruktor',
  email: 'a@b.hr',
  phone: null,
  licenseNumber: null,
  active: true,
  categoryCodes: ['B'],
  availabilityRules: [],
);

class LessonsStub extends Cubit<LessonsState> implements LessonsCubit {
  LessonsStub()
    : super(
        LessonsState.initial().copyWith(
          status: LessonsStatus.loaded,
          candidates: [
            candidate('Ana', 'Ivan'),
            candidate('Mia', 'Marko'),
            candidate('Bez', null),
          ],
          instructors: [
            instructor('Ivan'),
            instructor('Marko'),
            instructor('Prazan'),
          ],
        ),
      );
  SaveLesson? saved;
  @override
  Future<bool> create(SaveLesson lesson) async {
    saved = lesson;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CandidatesStub extends Cubit<CandidatesState> implements CandidatesCubit {
  CandidatesStub()
    : super(
        CandidatesState(
          status: CandidatesStatus.loaded,
          instructors: [instructor('Ivan')],
        ),
      );
  UpdateCandidate? saved;
  @override
  Future<bool> update(String id, UpdateCandidate candidate) async {
    saved = candidate;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'admin first selects instructor and sees only currently assigned candidates',
    (tester) async {
      final cubit = LessonsStub();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<LessonsCubit>.value(
              value: cubit,
              child: LessonDialog(initialStartAt: DateTime(2030, 1, 1, 10)),
            ),
          ),
        ),
      );
      expect(find.text('Prvo odaberite instruktora.'), findsOneWidget);
      final instructorField = find
          .byType(DropdownButtonFormField<String>)
          .at(0);
      Future<void> chooseInstructor(String name) async {
        await tester.tap(instructorField);
        await tester.pumpAndSettle();
        await tester.tap(find.text('$name Instruktor').last);
        await tester.pumpAndSettle();
      }

      await chooseInstructor('Ivan');
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Ana Kandidat'), findsOneWidget);
      expect(find.text('Mia Kandidat'), findsNothing);
      expect(find.text('Bez Kandidat'), findsNothing);
      await tester.tap(find.text('Ana Kandidat'));
      await tester.pumpAndSettle();
      await chooseInstructor('Marko');
      expect(find.text('Ana Kandidat'), findsNothing);
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(cubit.saved, isNull);
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mia Kandidat').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(cubit.saved?.candidateId, 'Mia');
      expect(cubit.saved?.instructorId, 'Marko');
      await chooseInstructor('Prazan');
      expect(
        find.text('Odabrani instruktor nema dodijeljenih kandidata.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );
  testWidgets(
    'existing candidate login can change password or keep it unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = CandidatesStub();
      final progress = hoursCubit(HoursRepository());
      await progress.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CandidatesCubit>.value(value: cubit),
                BlocProvider.value(value: progress),
              ],
              child: CandidateDialog(
                candidate: candidate('Ana', 'Ivan', hasLogin: true),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Email za prijavu: login@example.com'), findsOneWidget);
      final field = find.widgetWithText(
        TextFormField,
        'Nova lozinka za kandidatsku aplikaciju',
      );
      expect(tester.widget<TextFormField>(field).controller!.text, isEmpty);
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(cubit.saved, isNotNull);
      expect(
        UpdateCandidateModel.fromEntity(
          cubit.saved!,
        ).toJson().containsKey('loginPassword'),
        isFalse,
      );
      cubit.saved = null;
      await tester.enterText(field, 'short');
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(cubit.saved, isNull);
      expect(find.text('Lozinka mora imati od 8 do 72 znaka.'), findsOneWidget);
      await tester.enterText(field, 'UpdatedPass123!');
      await tester.tap(find.text('Spremi'));
      await tester.pumpAndSettle();
      expect(
        UpdateCandidateModel.fromEntity(cubit.saved!).toJson()['loginPassword'],
        'UpdatedPass123!',
      );
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      await progress.close();
    },
  );
  testWidgets('candidate profile shows hours and saves validated target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = CandidatesStub();
    final progress = hoursCubit(HoursRepository());
    await progress.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CandidatesCubit>.value(value: cubit),
              BlocProvider.value(value: progress),
            ],
            child: CandidateDialog(candidate: candidate('Ana', 'Ivan')),
          ),
        ),
      ),
    );
    expect(find.text('25/35 sati odrađeno'), findsOneWidget);
    final field = find.widgetWithText(
      TextFormField,
      'Potreban broj sati vožnje',
    );
    await tester.enterText(field, '0');
    await tester.tap(find.text('Spremi'));
    await tester.pumpAndSettle();
    expect(find.text('Unesite pozitivan cijeli broj.'), findsOneWidget);
    expect(cubit.saved, isNull);
    await tester.enterText(field, '30');
    await tester.tap(find.text('Spremi'));
    await tester.pumpAndSettle();
    expect(cubit.saved?.requiredDrivingHours, 30);
    expect(
      UpdateCandidateModel.fromEntity(
        cubit.saved!,
      ).toJson()['requiredDrivingHours'],
      30,
    );
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    await progress.close();
  });
}
