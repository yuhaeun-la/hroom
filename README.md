# 🏡 H-Room
## 멘토-멘티 관계 관리 앱

> **성장과 발전을 위한 스마트한 멘토링 플랫폼**

H-Room은 멘토와 멘티 간의 체계적인 관계 관리를 위한 Flutter 기반 모바일 애플리케이션입니다.

---

## 🎯 **주요 기능**

### 👥 **관계 관리**
- **초대 코드 시스템**: 멘토가 생성한 코드로 멘티와 안전하게 연결
- **역할 기반 권한**: 멘토와 멘티에게 맞춤형 기능 제공

### 📋 **규칙 & 체크리스트**
- **규칙 생성**: 멘토가 멘티를 위한 맞춤형 규칙 설정
- **일일 체크리스트**: 멘티의 규칙 완료 현황 실시간 추적
- **진행률 시각화**: 성취도를 한눈에 파악할 수 있는 대시보드

### 🎁 **포인트 & 보상 시스템**
- **포인트 획득**: 규칙 완료시 자동 포인트 지급
- **레벨 시스템**: 누적 포인트에 따른 성장 단계 표시
- **보상 상점**: 포인트로 구매 가능한 보상 아이템

### 📊 **성장 추적**
- **성장 지수**: 멘티의 발전 정도를 시각적으로 표현
- **멘토링 온도계**: 오늘의 활동 기반 관계 온도 측정
- **주간 진행률**: 시간별 성과 분석 차트

### 📝 **감정 일지**
- **일지 작성**: 멘티의 감정과 생각 기록
- **댓글 시스템**: 멘토의 피드백과 소통 채널

---

## 🛠 **기술 스택**

### **Frontend**
- **Flutter** - 크로스 플랫폼 모바일 앱 개발
- **Riverpod** - 상태 관리
- **fl_chart** - 데이터 시각화
- **Google Fonts** - 타이포그래피

### **Backend**
- **Supabase** - Backend as a Service
  - **PostgreSQL** - 관계형 데이터베이스
  - **Authentication** - 사용자 인증 관리
  - **Row Level Security** - 데이터 보안
  - **Real-time** - 실시간 데이터 동기화

---

## 🚀 **시작하기**

### **사전 요구사항**
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- iOS Simulator / Android Emulator
- Supabase 계정

### **설치 및 실행**

1. **프로젝트 클론**
   ```bash
   git clone https://github.com/yuhaeun-la/hroom.git
   cd hroom
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **Supabase 설정**
   - `lib/config/supabase_config.dart`에서 Supabase URL과 API 키 설정
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **앱 실행**
   ```bash
   flutter run
   ```

---

## 📱 **주요 화면**

### 🔐 **인증**
- 회원가입 및 이메일 인증
- 로그인 및 자동 로그인
- 역할 선택 (멘토/멘티)

### 📊 **대시보드**
- 실시간 성장 현황
- 오늘의 활동 요약
- 주간 진행률 차트
- 최근 활동 내역

### 👨‍🏫 **멘토 전용**
- 초대 코드 생성
- 규칙 생성 및 관리
- 보상/처벌 아이템 관리
- 멘티 진행 상황 모니터링

### 👨‍🎓 **멘티 전용**
- 초대 코드로 멘토와 연결
- 오늘의 체크리스트
- 포인트 및 레벨 확인
- 보상 상점 이용
- 감정 일지 작성

---

## 🎨 **디자인 시스템**

- **색상**: 따뜻하고 친근한 블루/그린 계열
- **타이포그래피**: Google Fonts - 가독성 중심
- **레이아웃**: 모바일 퍼스트, 직관적인 네비게이션
- **애니메이션**: 부드러운 전환과 피드백

---

## 🤝 **기여하기**

H-Room 프로젝트에 기여를 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 **라이선스**

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

---

## 📞 **연락처**

**개발자**: 유하은  
**GitHub**: [@yuhaeun-la](https://github.com/yuhaeun-la)

---

<div align="center">

**🌱 성장하는 관계, 발전하는 미래 🌱**

*H-Room과 함께 더 나은 멘토링 경험을 만들어보세요!*

</div>
