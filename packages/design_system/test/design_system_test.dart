import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_design_system/design_system.dart';

void main() {
  for (final width in [320.0, 1400.0]) {
    testWidgets('shared components fit width $width and large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: DrivingSchoolTheme.light(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: const SingleChildScrollView(
                child: AppPage(
                  child: AppEmptyState(
                    title: 'Nema termina',
                    message: 'Ovdje će biti prikazane tvoje vožnje.',
                    action: AppStatusBadge(
                      label: 'Potvrđeno',
                      isPositive: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Nema termina'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppCard)).width,
        lessThanOrEqualTo(AppSpacing.contentWidth),
      );
    });
  }
}
