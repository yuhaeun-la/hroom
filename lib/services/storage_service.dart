import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';

  // 로그인 상태 저장
  static Future<void> saveLoginState({
    required bool isLoggedIn,
    required String userEmail,
    required String userId,
    bool rememberMe = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setBool(_rememberMeKey, rememberMe);
    
    if (rememberMe) {
      await prefs.setString(_userEmailKey, userEmail);
      await prefs.setString(_userIdKey, userId);
    }
  }

  // 로그인 상태 불러오기
  static Future<Map<String, dynamic>> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
      'userEmail': prefs.getString(_userEmailKey) ?? '',
      'userId': prefs.getString(_userIdKey) ?? '',
      'rememberMe': prefs.getBool(_rememberMeKey) ?? false,
    };
  }

  // 로그아웃 시 저장된 데이터 삭제
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_rememberMeKey);
  }

  // "로그인 상태 유지" 설정 저장
  static Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
  }

  // "로그인 상태 유지" 설정 불러오기
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }
}
