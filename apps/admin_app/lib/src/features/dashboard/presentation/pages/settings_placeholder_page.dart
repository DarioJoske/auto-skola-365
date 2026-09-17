import 'package:flutter/material.dart';

final class SettingsPlaceholderPage extends StatelessWidget {
  const SettingsPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Postavke',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
