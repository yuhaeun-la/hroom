import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // 실제 Supabase 프로젝트 정보
  static const String supabaseUrl = 'https://wirhpculchpqhvexkwvd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndpcmhwY3VsY2hwcWh2ZXhrd3ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1MjkzNTYsImV4cCI6MjA3MDEwNTM1Nn0.if9W57HFmds9HB_k9pam65Mu95uVc_TcLBRd62jy8CA'; // Supabase anon public key

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}

// Supabase 클라이언트 전역 접근
final supabase = Supabase.instance.client;
