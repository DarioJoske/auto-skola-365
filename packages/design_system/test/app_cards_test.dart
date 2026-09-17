import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  testWidgets(
    'progress displays totals above target, omits unknown target and preserves data on refresh',
    (tester) async {
      Widget card({double? progress, bool loading = false}) => testApp(
        AppProgressCard(
          title: 'Odrađeni sati',
          valueLabel: '37 / 35',
          subtitle: 'nastavnih sati',
          message: 'Spremnost za ispit potvrđuje instruktor.',
          progress: progress,
          isLoading: loading,
          progressSemanticsValue: '37 od 35 sati',
        ),
      );
      await tester.pumpWidget(card(progress: 37 / 35));
      expect(find.text('37 / 35'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      await tester.pumpWidget(card());
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('37 / 35'), findsOneWidget);
      await tester.pumpWidget(card(loading: true));
      expect(find.text('37 / 35'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
    },
  );

  testWidgets('notice offers retry alongside existing lesson data', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            const AppLessonCard(
              timeLabel: '16:30 – 17:30',
              title: 'Ana Horvat',
              details: '60 minuta',
              statusLabel: 'Potvrđeno',
            ),
            AppNotice(
              title: 'Osvježavanje nije uspjelo',
              message: 'Termin nije moguće učitati.',
              tone: AppTone.error,
              action: AppButton(
                label: 'Pokušaj ponovno',
                onPressed: () => retries++,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Ana Horvat'), findsOneWidget);
    expect(find.text('Termin nije moguće učitati.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovno'));
    expect(retries, 1);
  });

  testWidgets(
    'all badge tones have readable labels and honor semantic theme overrides',
    (tester) async {
      final theme = DrivingSchoolTheme.light().copyWith(
        extensions: const [
          AppSemanticColors(
            success: Colors.purple,
            successContainer: Colors.yellow,
          ),
        ],
      );
      await tester.pumpWidget(
        testApp(
          Wrap(
            children: [
              for (final tone in AppTone.values)
                AppStatusBadge(label: tone.name, tone: tone),
              const AppStatusBadge(label: 'Legacy', isPositive: true),
            ],
          ),
          theme: theme,
        ),
      );
      for (final tone in AppTone.values) {
        expect(find.text(tone.name), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.text('success')).style!.color,
        Colors.purple,
      );
      expect(
        tester.widget<Text>(find.text('Legacy')).style!.color,
        Colors.purple,
      );
    },
  );

  testWidgets('list item forwards tap and exposes its content to semantics', (
    tester,
  ) async {
    var calls = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        AppListItem(
          title: 'Ana Horvat',
          subtitle: 'B kategorija',
          onTap: () => calls++,
        ),
      ),
    );
    await tester.tap(find.text('Ana Horvat'));
    expect(calls, 1);
    expect(find.bySemanticsLabel(RegExp('Ana Horvat')), findsWidgets);
    semantics.dispose();
  });

  testWidgets('page padding follows parent width instead of full window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: AppPage(
                child: Container(key: const Key('content'), height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 288);
  });
}
