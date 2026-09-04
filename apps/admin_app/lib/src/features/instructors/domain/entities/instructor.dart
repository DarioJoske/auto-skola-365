class Instructor {
  const Instructor({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.membershipId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.active,
    required this.categoryCodes,
    required this.availabilityRules,
  });

  final String id;
  final String schoolId;
  final String userId;
  final String membershipId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? licenseNumber;
  final bool active;
  final List<String> categoryCodes;
  final List<InstructorAvailabilityRule> availabilityRules;

  String get fullName => '$firstName $lastName';
}

class InstructorAvailabilityRule {
  const InstructorAvailabilityRule({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final String? id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
}
