import '../../domain/entities/instructor.dart';
import '../../domain/entities/save_instructor.dart';

class SaveInstructorModel {
  const SaveInstructorModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.active,
    required this.categoryCodes,
    required this.availabilityRules,
  });

  factory SaveInstructorModel.fromEntity(SaveInstructor instructor) {
    return SaveInstructorModel(
      firstName: instructor.firstName,
      lastName: instructor.lastName,
      email: instructor.email,
      phone: instructor.phone,
      licenseNumber: instructor.licenseNumber,
      active: instructor.active,
      categoryCodes: instructor.categoryCodes,
      availabilityRules: instructor.availabilityRules,
    );
  }

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? licenseNumber;
  final bool active;
  final List<String> categoryCodes;
  final List<InstructorAvailabilityRule> availabilityRules;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'active': active,
      'categoryCodes': categoryCodes,
      'availabilityRules': availabilityRules
          .map(
            (rule) => {
              'dayOfWeek': rule.dayOfWeek,
              'startTime': rule.startTime,
              'endTime': rule.endTime,
            },
          )
          .toList(),
    };
  }
}
