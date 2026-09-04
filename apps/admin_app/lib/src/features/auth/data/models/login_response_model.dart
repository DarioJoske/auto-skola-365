import 'current_user_model.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresInMinutes,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresInMinutes: json['expiresInMinutes'] as int,
      user: CurrentUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresInMinutes;
  final CurrentUserModel user;
}
