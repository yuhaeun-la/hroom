-- Supabase에서 가입된 사용자들 확인
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  confirmed_at,
  last_sign_in_at
FROM auth.users
ORDER BY created_at DESC;

-- 사용자 프로필 확인  
SELECT 
  up.id,
  up.display_name,
  up.role,
  up.created_at,
  u.email,
  u.email_confirmed_at
FROM users_profile up
LEFT JOIN auth.users u ON up.id = u.id
ORDER BY up.created_at DESC;
