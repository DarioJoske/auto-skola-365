import 'membership.dart';

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.status,
    required this.memberships,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String status;
  final List<Membership> memberships;

  String get fullName => '$firstName $lastName';
  Membership? get primaryMembership =>
      memberships.isEmpty ? null : memberships.first;
}
