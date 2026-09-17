import 'package:flutter/material.dart';

const lessonStatuses = ['REQUESTED', 'CONFIRMED', 'CANCELLED'];

String lessonStatusLabel(String status) {
  return switch (status) {
    'REQUESTED' => 'Za potvrdu',
    'CONFIRMED' => 'Potvrdeno',
    'COMPLETED' => 'Odradeno',
    'CANCELLED' => 'Otkazano',
    'NO_SHOW' => 'Nije dosao',
    _ => status,
  };
}

Color statusColor(BuildContext context, String status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    'REQUESTED' => colors.tertiary,
    'CONFIRMED' => colors.primary,
    'CANCELLED' => colors.outline,
    'COMPLETED' => Colors.green.shade700,
    'NO_SHOW' => colors.error,
    _ => colors.secondary,
  };
}

String formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
}

String formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
