import 'package:flutter/material.dart';
import 'app_page.dart';
import 'app_notice.dart';

/// An honest empty destination for a planned feature.
final class AppPlaceholderPage extends StatelessWidget {
  const AppPlaceholderPage({
    required this.title,
    required this.description,
    this.action,
    super.key,
  });
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          AppNotice(title: 'U pripremi', message: description, action: action),
        ],
      ),
    ),
  );
}
