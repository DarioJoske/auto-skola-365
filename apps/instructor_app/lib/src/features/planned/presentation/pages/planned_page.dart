import 'package:auto_skola_design_system/design_system.dart';
import 'package:flutter/material.dart';

final class PlannedPage extends StatelessWidget {
  const PlannedPage({
    required this.title,
    required this.description,
    super.key,
  });
  final String title, description;

  @override
  Widget build(BuildContext context) =>
      AppPlaceholderPage(title: title, description: description);
}
