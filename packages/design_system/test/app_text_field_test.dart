import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  testWidgets(
    'validation and backend errors preserve entered text and allow retry',
    (tester) async {
      final controller = TextEditingController();
      final form = GlobalKey<FormState>();
      addTearDown(controller.dispose);
      Widget build({String? error}) => testApp(
        Form(
          key: form,
          child: AppTextField(
            label: 'E-mail adresa',
            controller: controller,
            errorText: error,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || !value.contains('@')
                ? 'Unesite valjanu e-mail adresu.'
                : null,
          ),
        ),
      );
      await tester.pumpWidget(build());
      await tester.enterText(find.byType(TextFormField), 'ana');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Unesite valjanu e-mail adresu.'), findsOneWidget);
      expect(controller.text, 'ana');

      await tester.enterText(find.byType(TextFormField), 'ana@example.com');
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpWidget(build(error: 'Email već ima korisnički račun.'));
      expect(find.text('Email već ima korisnički račun.'), findsOneWidget);
      expect(controller.text, 'ana@example.com');
      await tester.pumpWidget(build());
      expect(controller.text, 'ana@example.com');
      expect(find.text('Email već ima korisnički račun.'), findsNothing);
    },
  );

  testWidgets(
    'disabled field does not focus; enabled field retains label and input options',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Widget build(bool enabled) => testApp(
        AppTextField(
          label: 'Ime i prezime',
          initialValue: 'Ana',
          focusNode: focus,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
      );
      await tester.pumpWidget(build(false));
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      await tester.pumpWidget(build(true));
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.text('Ime i prezime'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textCapitalization, TextCapitalization.words);
      expect(field.textInputAction, TextInputAction.next);
      expect(
        field.decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
    },
  );
}
