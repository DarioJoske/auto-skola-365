import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  for (final variant in AppButtonVariant.values) {
    testWidgets(
      '$variant fires on release and blocks disabled/loading actions',
      (tester) async {
        var calls = 0;
        Widget button({bool loading = false, bool enabled = true}) => testApp(
          AppButton(
            label: 'Spremi',
            loadingLabel: 'Spremanje…',
            variant: variant,
            isLoading: loading,
            onPressed: enabled ? () => calls++ : null,
          ),
        );
        await tester.pumpWidget(button());
        final target = find.byType(AppButton);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        final gesture = await tester.startGesture(tester.getCenter(target));
        await tester.pump(const Duration(milliseconds: 100));
        expect(calls, 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(calls, 1);

        await tester.pumpWidget(button(loading: true));
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Spremanje…'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(calls, 1);

        await tester.pumpWidget(button(enabled: false));
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.text('Spremi'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(calls, 1);

        await tester.pumpWidget(button());
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(calls, 2);
      },
    );

    testWidgets('$variant exposes focus and responds to keyboard activation', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final previous = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      var calls = 0;
      await tester.pumpWidget(
        testApp(
          AppButton(
            label: 'Spremi',
            variant: variant,
            focusNode: focus,
            onPressed: () => calls++,
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Material),
        ),
      );
      expect((material.shape! as OutlinedBorder).side.width, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  }

  testWidgets('long label and loading state fit a narrow large-text layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      testApp(
        const AppButton(
          label: 'Spremi sve promjene kandidata',
          loadingLabel: 'Spremanje promjena kandidata…',
          onPressed: null,
          isLoading: true,
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Spremanje promjena kandidata…'), findsOneWidget);
  });
}
