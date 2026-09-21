import 'package:flutter/material.dart';
import 'package:auto_skola_design_system/design_system.dart';

const lessonFilterStatuses = [
  'REQUESTED',
  'CONFIRMED',
  'COMPLETED',
  'CANCELLED',
  'NO_SHOW',
];

AppTone lessonStatusTone(String status) => switch (status) {
  'CONFIRMED' || 'COMPLETED' => AppTone.success,
  'REQUESTED' => AppTone.warning,
  'NO_SHOW' => AppTone.error,
  _ => AppTone.neutral,
};

const lessonStatuses = ['REQUESTED', 'CONFIRMED', 'CANCELLED'];

String lessonStatusLabel(String status) {
  return switch (status) {
    'REQUESTED' => 'Čeka potvrdu',
    'CONFIRMED' => 'Potvrđeno',
    'COMPLETED' => 'Odrađeno',
    'CANCELLED' => 'Otkazano',
    'NO_SHOW' => 'Nedolazak',
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
