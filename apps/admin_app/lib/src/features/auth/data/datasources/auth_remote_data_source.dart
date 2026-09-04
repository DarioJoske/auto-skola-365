import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/current_user_model.dart';
import '../models/login_response_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> json;
    try {
      json =
          await _apiClient.postJson(
                '/api/auth/login',
                body: {'email': email, 'password': password},
              )
              as Map<String, dynamic>;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        throw const ApiException(
          'Email ili lozinka nisu ispravni.',
          statusCode: 401,
        );
      }
      rethrow;
    }

    return LoginResponseModel.fromJson(json);
  }

  Future<CurrentUserModel> me(String accessToken) async {
    final json =
        await _apiClient.getJson('/api/me', accessToken: accessToken)
            as Map<String, dynamic>;

    return CurrentUserModel.fromJson(json);
  }
}
