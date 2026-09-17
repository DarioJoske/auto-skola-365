import 'package:flutter/material.dart';
import '../theme/app_tone.dart';
import 'app_notice.dart';

final class AppInlineError extends StatelessWidget {
  const AppInlineError({
    required this.message,
    required this.onRetry,
    this.title = 'Podatke nije moguće učitati',
    super.key,
  });
  final String title, message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AppNotice(
    title: title,
    message: message,
    tone: AppTone.error,
    action: TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Pokušaj ponovno'),
    ),
  );
}

final class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    this.isRefreshing = false,
    this.label = 'Učitavanje…',
    super.key,
  });
  final bool isRefreshing;
  final String label;
  @override
  Widget build(BuildContext context) => isRefreshing
      ? LinearProgressIndicator(semanticsLabel: label)
      : Center(
          child: SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(semanticsLabel: label),
                const SizedBox(height: 16),
                Text(label),
              ],
            ),
          ),
        );
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showSessionExpired(BuildContext context) =>
    showAppSnackBar(context, 'Sesija je istekla. Prijavite se ponovno.');

Future<bool> showAppConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
