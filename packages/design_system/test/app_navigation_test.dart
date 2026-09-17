import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_design_system/previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  setUpAll(loadTestFonts);
  for (final width in [360.0, 390.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('navigation fits $width at text scale $scale and keyboard', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final mode = width >= 600
            ? AppNavigationMode.admin
            : AppNavigationMode.mobile;
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: DrivingSchoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: NavigationExample(mode: mode),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (width == 1024) expect(find.byType(NavigationRail), findsOneWidget);
        if (width == 1440) expect(find.text('autoškola 365'), findsOneWidget);
        if (width < 600) expect(find.byType(NavigationBar), findsOneWidget);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File(
            'build/previews/navigation-${width.toInt()}-$scale.png',
          );
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.enterText(find.byType(TextField), 'Sačuvana bilješka');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(find.text('Sačuvana bilješka'), findsOneWidget);
        if (width < 600) expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Prikaži grešku'));
        await tester.tap(find.text('Prikaži grešku'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Pokušaj ponovno'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pokušaj ponovno'));
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Sačuvana bilješka'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('admin resizing preserves input and drawer selection closes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      navigationPreviewWrapper(
        const NavigationExample(mode: AppNavigationMode.admin),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Sačuvaj unos');
    FocusManager.instance.primaryFocus?.unfocus();
    for (final width in [1024.0, 390.0, 1440.0, 360.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(find.text('Sačuvaj unos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Otvori navigaciju'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kandidati'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppNavigationShell>(find.byType(AppNavigationShell))
          .selectedIndex,
      1,
    );
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('Sačuvaj unos'), findsOneWidget);
  });

  testWidgets('confirmation returns choice and snackbar surfaces expiry', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () async {
                    result = await showAppConfirmation(
                      context,
                      title: 'Otkazati termin?',
                      message: 'Termin će biti otkazan.',
                      confirmLabel: 'Otkaži termin',
                    );
                  },
                  child: const Text('Otvori'),
                ),
                TextButton(
                  onPressed: () => showSessionExpired(context),
                  child: const Text('Sesija'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otkaži termin'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    await tester.tap(find.text('Sesija'));
    await tester.pump();
    expect(
      find.text('Sesija je istekla. Prijavite se ponovno.'),
      findsOneWidget,
    );
  });
  testWidgets('wide content scrolls horizontally to the final column', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppHorizontalScroll(
            child: SizedBox(
              width: 1600,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [Text('Prvi stupac'), Text('Zadnji stupac')],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Zadnji stupac').hitTestable(), findsNothing);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zadnji stupac').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
