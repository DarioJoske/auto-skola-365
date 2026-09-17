import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_skola_design_system/design_system.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/cubit/school_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/dashboard/presentation/pages/overview_view.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/cubit/instructor_overview_cubit.dart';
import 'package:auto_skola_365_admin_app/src/features/instructors/presentation/pages/instructor_overview_view.dart';
import 'overview_widget_test.dart' show SchoolStub, InstructorStub;

void main() {
  for (final screen in ['school', 'instructors']) {
    testWidgets('$screen renders inside the desktop shell', (tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
      final school = SchoolStub();
      final instructors = InstructorStub();
      addTearDown(school.close);
      addTearDown(instructors.close);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: DrivingSchoolTheme.light(),
          home: RepaintBoundary(
            key: boundaryKey,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SchoolOverviewCubit>.value(value: school),
                BlocProvider<InstructorOverviewCubit>.value(value: instructors),
              ],
              child: AppNavigationShell(
                mode: AppNavigationMode.admin,
                title: 'Autoškola · primjer',
                subtitle: 'Sintetički testni podaci',
                selectedIndex: screen == 'school' ? 0 : 2,
                onDestinationSelected: (_) {},
                destinations: const [
                  AppDestination(label: 'Pregled', icon: Icons.dashboard),
                  AppDestination(label: 'Kandidati', icon: Icons.people),
                  AppDestination(label: 'Instruktori', icon: Icons.badge),
                  AppDestination(label: 'Vožnje', icon: Icons.calendar_month),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: screen == 'school'
                      ? const OverviewView()
                      : const InstructorOverviewView(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Opt-in artifacts for visual review; normal test runs do not write files.
      if (Platform.environment['OVERVIEW_SCREENSHOTS']
          case final String output) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/$screen.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
