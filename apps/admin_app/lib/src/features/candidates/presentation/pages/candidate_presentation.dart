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
    'PASSED_THEORY' => 'Polozio teoriju',
    'IN_DRIVING' => 'Na voznji',
    'READY_FOR_EXAM' => 'Spreman za ispit',
    'EXAM_SCHEDULED' => 'Ispit zakazan',
    'PASSED' => 'Polozio',
    'DROPPED' => 'Odustao',
    'ARCHIVED' => 'Arhiviran',
    _ => status,
  };
}
