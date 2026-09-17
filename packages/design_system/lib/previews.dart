import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'design_system.dart';
import 'src/preview/admin_example.dart';
import 'src/preview/candidate_example.dart';
import 'src/preview/component_catalog.dart';
import 'src/preview/instructor_example.dart';

export 'src/preview/admin_example.dart';
export 'src/preview/candidate_example.dart';
export 'src/preview/component_catalog.dart';
export 'src/preview/instructor_example.dart';

Widget designSystemPreviewWrapper(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: DrivingSchoolTheme.light(),
  home: Scaffold(
    body: SingleChildScrollView(child: AppPage(child: child)),
  ),
);

@Preview(
  name: 'Admin · 1024',
  size: Size(1024, 900),
  wrapper: designSystemPreviewWrapper,
)
Widget adminPreview() => const AdminDesignSystemExample();

@Preview(
  name: 'Instruktor · 390',
  size: Size(390, 900),
  wrapper: designSystemPreviewWrapper,
)
Widget instructorPreview() => const InstructorDesignSystemExample();

@Preview(
  name: 'Kandidat · 360',
  size: Size(360, 900),
  wrapper: designSystemPreviewWrapper,
)
@Preview(
  name: 'Kandidat · veliki tekst',
  size: Size(360, 900),
  textScaleFactor: 2,
  wrapper: designSystemPreviewWrapper,
)
Widget candidatePreview() => const CandidateDesignSystemExample();

@Preview(
  name: 'Komponente · stanja',
  size: Size(720, 1000),
  wrapper: designSystemPreviewWrapper,
)
Widget componentsPreview() => const ComponentCatalog();
