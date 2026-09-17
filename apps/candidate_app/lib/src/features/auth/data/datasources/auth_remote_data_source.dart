import '../../../../core/api/api_client.dart';
import '../models/current_user_model.dart';
import '../models/login_response_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _apiClient.postJson(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    return LoginResponseModel.fromJson(json as Map<String, dynamic>);
  }

  Future<CurrentUserModel> getCurrentUser(String accessToken) async {
    final json = await _apiClient.getJson('/api/me', accessToken: accessToken);

    return CurrentUserModel.fromJson(json as Map<String, dynamic>);
  }
}
