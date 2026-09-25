import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/result.dart';
import 'package:auto_skola_365_instructor_app/src/core/api/failure.dart';
import 'package:auto_skola_365_instructor_app/src/features/availability/domain/entities/availability.dart';
import 'package:auto_skola_365_instructor_app/src/features/availability/domain/repositories/availability_repository.dart';
import 'package:auto_skola_365_instructor_app/src/features/availability/domain/usecases/manage_availability.dart';
import 'package:auto_skola_365_instructor_app/src/features/availability/presentation/cubit/availability_cubit.dart';
import 'package:auto_skola_365_instructor_app/src/features/availability/presentation/pages/availability_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_design_system/design_system.dart';

class AvailabilityFake implements AvailabilityRepository {
  final value = Availability(
    rules: [const WorkingPeriod(1, '08:00', '16:00')],
    blocks: [],
  );
  FutureEither<Availability> Function()? loading;
  FutureEither<Availability> Function(Availability)? saving;
  int calls = 0;
  @override
  FutureEither<Availability> load(
    String school,
    String token,
    String instructor,
  ) => loading?.call() ?? Future.value(Right(value));
  @override
  FutureEither<Availability> save(
    String school,
    String token,
    String instructor,
    Availability data,
  ) {
    calls++;
    return saving?.call(data) ?? Future.value(Right(data));
  }
}

AvailabilityCubit make(AvailabilityFake repo) =>
    AvailabilityCubit(ManageAvailability(repo), 'school', 'token', 'me');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
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
  });

  late AvailabilityFake repo;
  setUp(() => repo = AvailabilityFake());
  test('initial state has no data and no pending action', () {
    final c = make(repo);
    expect(c.state.data, isNull);
    expect(c.state.saving, isFalse);
    c.close();
  });
  blocTest<AvailabilityCubit, AvailabilityState>(
    'load, save failure retains data, retry succeeds',
    build: () => make(repo),
    act: (c) async {
      await c.load();
      repo.saving = (_) async =>
          const Left(Failure('Zauzeto', statusCode: 409));
      await c.save(repo.value);
      repo.saving = null;
      await c.save(repo.value);
    },
    expect: () => [
      isA<AvailabilityState>().having((s) => s.loading, 'loading', true),
      isA<AvailabilityState>().having((s) => s.data, 'data', repo.value),
      isA<AvailabilityState>().having((s) => s.saving, 'saving', true),
      isA<AvailabilityState>()
          .having((s) => s.actionError, 'error', true)
          .having((s) => s.data, 'preserved', repo.value),
      isA<AvailabilityState>().having((s) => s.saving, 'retry', true),
      isA<AvailabilityState>().having((s) => s.saved, 'saved', 1),
    ],
  );
  test(
    'duplicate saves are ignored and superseded loads cannot overwrite save',
    () async {
      final c = make(repo);
      await c.load();
      final old = Completer<Either<Failure, Availability>>();
      repo.loading = () => old.future;
      final load = c.load();
      final pending = Completer<Either<Failure, Availability>>();
      repo.saving = (_) => pending.future;
      final save = c.save(repo.value);
      await c.save(repo.value);
      expect(repo.calls, 1);
      pending.complete(Right(repo.value));
      await save;
      old.complete(const Left(Failure('Stari odgovor')));
      await load;
      expect(c.state.saved, 1);
      expect(c.state.failure, isNull);
      await c.close();
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'availability draft survives save conflict at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = make(repo);
        await c.load();
        addTearDown(c.close);
        repo.saving = (_) async => const Left(
          Failure('Postojeći termin blokira promjenu.', statusCode: 409),
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: DrivingSchoolTheme.light(),
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: BlocProvider.value(
                    value: c,
                    child: const AvailabilityView(),
                  ),
                ),
              ),
            ),
          ),
        );
        final directory = Platform.environment['REQUEST_SCREENSHOTS'];
        if (directory != null && scale == 1) {
          await tester.runAsync(() async {
            await Directory(directory).create(recursive: true);
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$directory/I08.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byTooltip('Ukloni radno vrijeme'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Spremi dostupnost'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Spremi dostupnost'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spremi dostupnost'));
        await tester.pumpAndSettle();
        expect(find.text('Postojeći termin blokira promjenu.'), findsOneWidget);
        expect(find.text('Ponedjeljak'), findsNothing);
        expect(c.state.saved, 0);
        repo.saving = null;
        await tester.ensureVisible(find.text('Spremi dostupnost'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spremi dostupnost'));
        await tester.pumpAndSettle();
        expect(c.state.data!.rules, isEmpty);
        expect(c.state.saved, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
