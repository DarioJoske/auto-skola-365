import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget testApp(Widget child, {double textScale = 1, ThemeData? theme}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? DrivingSchoolTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: SingleChildScrollView(child: AppPage(child: child)),
          ),
        ),
      ),
    );

Future<void> loadTestFonts() async {
  final fonts = FontLoader('packages/auto_skola_design_system/SchoolSans')
    ..addFont(
      rootBundle.load(
        'packages/auto_skola_design_system/assets/fonts/Roboto-Regular.ttf',
      ),
    )
    ..addFont(
      rootBundle.load(
        'packages/auto_skola_design_system/assets/fonts/Roboto-Bold.ttf',
      ),
    );
  await fonts.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}
