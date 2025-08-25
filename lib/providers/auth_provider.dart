import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

// 인증 상태 모델
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null && profile != null;
}

// 인증 제공자
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _initialize();
  }

  void _initialize() async {
    // 저장된 로그인 상태 확인
    final loginState = await StorageService.getLoginState();
    
    // 현재 Supabase 세션 확인
    final session = supabase.auth.currentSession;
    
    if (session != null) {
      // 활성 세션이 있으면 프로필 로드
      state = state.copyWith(user: session.user);
      _loadProfile();
    } else if (loginState['rememberMe'] == true && loginState['isLoggedIn'] == true) {
      // 저장된 자동 로그인 상태가 있으면 세션 복원 시도
      await _tryRestoreSession();
    }

    // 인증 상태 변경 리스너
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        state = state.copyWith(user: session.user);
        _loadProfile();
        _saveLoginState(); // 로그인 상태 저장
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthState();
        StorageService.clearLoginState(); // 저장된 상태 삭제
      }
    });
  }

  // 세션 복원 시도
  Future<void> _tryRestoreSession() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Supabase에서 현재 세션 새로고침 시도
      final response = await supabase.auth.refreshSession();
      
      if (response.session != null) {
        state = state.copyWith(user: response.session!.user);
        await _loadProfile();
      } else {
        // 세션 복원 실패 시 저장된 상태 삭제
        await StorageService.clearLoginState();
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // 복원 실패 시 저장된 상태 삭제
      await StorageService.clearLoginState();
      state = state.copyWith(isLoading: false);
    }
  }

  // 로그인 상태 저장
  Future<void> _saveLoginState() async {
    if (state.user != null && state.profile != null) {
      await StorageService.saveLoginState(
        isLoggedIn: true,
        userEmail: state.user!.email!,
        userId: state.user!.id,
        rememberMe: true,
      );
    }
  }

  // 프로필 로드
  Future<void> _loadProfile() async {
    if (state.user == null) return;

    try {
      final response = await supabase
          .from('users_profile')
          .select()
          .eq('id', state.user!.id)
          .single();

      final profile = UserProfile.fromJson(response);
      state = state.copyWith(profile: profile);
    } catch (e) {
      // 프로필이 없는 경우 (신규 사용자)
      state = state.copyWith(error: null);
    }
  }

  // 이메일 회원가입
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 프로필 생성
        await supabase.from('users_profile').insert({
          'id': response.user!.id,
          'display_name': displayName,
          'role': role,
        });

        await _loadProfile();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 이메일 로그인
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('AuthProvider: 로그인 시도 - $email'); // 디버그 로그
      
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('AuthProvider: 로그인 응답 - ${response.user?.id}'); // 디버그 로그
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('AuthProvider: 로그인 오류 - $e'); // 디버그 로그
      
      String errorMessage = e.toString();
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = '이메일 또는 비밀번호가 잘못되었습니다.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = '이메일 인증이 완료되지 않았습니다.';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      } else if (e.toString().contains('Network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await supabase.auth.signOut();
    await StorageService.clearLoginState();
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (state.profile == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await supabase
            .from('users_profile')
            .update(updates)
            .eq('id', state.profile!.id);

        final updatedProfile = state.profile!.copyWith(
          displayName: displayName,
          avatarUrl: avatarUrl,
        );

        state = state.copyWith(
          profile: updatedProfile,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// 인증 제공자 인스턴스
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
