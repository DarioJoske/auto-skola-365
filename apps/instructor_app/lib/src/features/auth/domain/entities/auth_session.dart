import 'current_user.dart';
import 'membership.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    required this.instructorMembership,
  });

  final String accessToken;
  final CurrentUser user;
  final Membership instructorMembership;
}
