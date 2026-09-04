import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'admin_access_token';

  Future<String?> readAccessToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_accessTokenKey);
  }

  Future<void> saveAccessToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, token);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessTokenKey);
  }
}
