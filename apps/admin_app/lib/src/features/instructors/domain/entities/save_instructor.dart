import 'instructor.dart';

class SaveInstructor {
  const SaveInstructor({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.licenseNumber,
    required this.active,
    required this.categoryCodes,
    required this.availabilityRules,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? password;
  final String? phone;
  final String? licenseNumber;
  final bool active;
  final List<String> categoryCodes;
  final List<InstructorAvailabilityRule> availabilityRules;
}
