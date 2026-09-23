import 'package:auto_skola_design_system/design_system.dart';

const candidateStatuses = [
  'LEAD',
  'ENROLLED',
  'IN_THEORY',
  'PASSED_THEORY',
  'IN_DRIVING',
  'READY_FOR_EXAM',
  'EXAM_SCHEDULED',
  'PASSED',
  'DROPPED',
  'ARCHIVED',
];

const categoryCodes = ['A', 'B', 'C', 'D', 'CE'];
const withoutInstructorFilterValue = '__without_instructor__';

String editableCandidateStatus(String status) {
  return candidateStatuses.contains(status) ? status : 'ENROLLED';
}

String candidateStatusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Aktivan',
    'LEAD' => 'Lead',
    'ENROLLED' => 'Upisan',
    'IN_THEORY' => 'Na teoriji',
    'PASSED_THEORY' => 'Položio teoriju',
    'IN_DRIVING' => 'Na vožnji',
    'READY_FOR_EXAM' => 'Spreman za ispit',
    'EXAM_SCHEDULED' => 'Ispit zakazan',
    'PASSED' => 'Položio',
    'DROPPED' => 'Odustao',
    'ARCHIVED' => 'Arhiviran',
    _ => status,
  };
}

AppTone candidateStatusTone(String status) => switch (status) {
  'PASSED' => AppTone.success,
  'READY_FOR_EXAM' || 'EXAM_SCHEDULED' => AppTone.warning,
  'DROPPED' => AppTone.error,
  'ARCHIVED' || 'LEAD' => AppTone.neutral,
  _ => AppTone.info,
};
