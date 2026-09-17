import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_design_system/previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestFonts);
  final examples = <String, Widget>{
    'admin': const AdminDesignSystemExample(),
    'instructor': const InstructorDesignSystemExample(),
    'candidate': const CandidateDesignSystemExample(),
    'components': const ComponentCatalog(),
  };
  for (final entry in examples.entries) {
    for (final width in [320.0, 390.0, 1024.0]) {
      testWidgets('${entry.key} fits $width with double text size', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(testApp(entry.value, textScale: 2));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -700),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('${entry.key} renders bundled fonts for visual review', (
      tester,
    ) async {
      final width = entry.key == 'admin' || entry.key == 'components'
          ? 1024.0
          : 390.0;
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.pumpWidget(
          RepaintBoundary(key: boundaryKey, child: testApp(entry.value)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File('build/previews/${entry.key}.png');
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      } finally {
        debugDisableShadows = previousShadows;
      }
    });
  }

  testWidgets(
    'admin example retains entered data across saving, failure and retry',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(testApp(const AdminDesignSystemExample()));
      await tester.enterText(find.byType(TextFormField).first, 'Iva Ivić');
      await tester.tap(find.text('Spremi'));
      await tester.pump();
      expect(find.text('Spremanje…'), findsOneWidget);
      await tester.tap(find.text('Prikaži grešku'));
      await tester.pumpAndSettle();
      expect(find.text('Spremanje nije uspjelo'), findsOneWidget);
      expect(find.text('Iva Ivić'), findsOneWidget);
      await tester.tap(find.text('Pokušaj ponovno'));
      await tester.pump();
      expect(find.text('Spremanje…'), findsOneWidget);
      expect(find.text('Iva Ivić'), findsOneWidget);
    },
  );
}
