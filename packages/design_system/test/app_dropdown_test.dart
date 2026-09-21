import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keyboard selection, Escape and disabled fields', (tester) async {
    String? selected;
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: DrivingSchoolTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: AppDropdownFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Instruktor'),
                  items: const [
                    AppDropdownOption(value: null, label: 'Svi'),
                    AppDropdownOption(value: 'ivan', label: 'Ivan'),
                    AppDropdownOption(
                      value: 'petra',
                      label: 'Petra',
                      enabled: false,
                    ),
                  ],
                  onChanged: enabled
                      ? (value) => setState(() => selected = value)
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MenuItemButton, 'Ivan'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 'ivan');
    await tester.tap(find.byType(AppDropdownFormField<String>));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(selected, 'ivan');
    update(() => enabled = false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppDropdownFormField<String>));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('outlined controls and anchored menus at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = true);
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        final boundary = GlobalKey();
        String? selection;
        final form = GlobalKey<FormState>();
        await (FontLoader(
              'packages/auto_skola_design_system/SchoolSans',
            )..addFont(
              rootBundle.load(
                'packages/auto_skola_design_system/assets/fonts/Roboto-Regular.ttf',
              ),
            ))
            .load();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: DrivingSchoolTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: form,
                      child: StatefulBuilder(
                        builder: (context, setState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Podaci kandidata'),
                            const SizedBox(height: 24),
                            const AppTextField(
                              label: 'Ime i prezime',
                              initialValue: 'Ana Horvat',
                            ),
                            const SizedBox(height: 24),
                            AppDropdownFormField<String>(
                              initialValue: selection,
                              decoration: const InputDecoration(
                                labelText: 'Instruktor',
                              ),
                              validator: (value) => value == null
                                  ? 'Odaberite instruktora.'
                                  : null,
                              items: [
                                const AppDropdownOption(
                                  value: null,
                                  label: 'Bez instruktora',
                                ),
                                const AppDropdownOption(
                                  value: 'ivan',
                                  label: 'Ivan Instruktor',
                                ),
                                for (var i = 0; i < 12; i++)
                                  AppDropdownOption(
                                    value: '$i',
                                    label:
                                        'Instruktor s vrlo dugim imenom i prezimenom $i',
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => selection = value),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () => setState(() => selection = null),
                              child: const Text('Očisti'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          final decoration = field.decoration!.applyDefaults(
            DrivingSchoolTheme.light().inputDecorationTheme,
          );
          expect(decoration.filled, isFalse);
          expect(decoration.enabledBorder, isA<OutlineInputBorder>());
        }
        if (scale == 1) {
          expect(tester.getSize(find.byType(InputDecorator).first).height, 56);
          expect(tester.getSize(find.byType(InputDecorator).last).height, 56);
        }
        await tester.tap(find.byType(AppDropdownFormField<String>));
        await tester.pumpAndSettle();
        expect(find.byType(MenuItemButton), findsWidgets);
        expect(
          tester
              .getSize(find.widgetWithText(MenuItemButton, 'Ivan Instruktor'))
              .height,
          greaterThanOrEqualTo(48),
        );
        if (Platform.environment['MENU_SCREENSHOTS'] case final String output) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File(
              '$output/menu-${width.toInt()}-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(
          find.widgetWithText(MenuItemButton, 'Ivan Instruktor'),
        );
        await tester.pumpAndSettle();
        expect(selection, 'ivan');
        expect(form.currentState!.validate(), isTrue);
        await tester.tap(find.text('Očisti'));
        await tester.pumpAndSettle();
        expect(selection, isNull);
        expect(form.currentState!.validate(), isFalse);
        await tester.pumpAndSettle();
        expect(find.text('Odaberite instruktora.'), findsOneWidget);
        debugDisableShadows = true;
        expect(tester.takeException(), isNull);
      });
    }
  }
}
