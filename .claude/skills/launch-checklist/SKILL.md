---
name: launch-checklist
description: 출시 준비 점검 및 개발 방향 가이드. Use this skill when the user asks about "출시", "launch", "release", "배포", "스토어", "app store", "play store", "출시 준비", "출시 점검", "MVP", "1차 출시", "릴리스", "배포 준비", "출시 가능", "ship", or any task involving assessing launch readiness, prioritizing features, or preparing for app store submission. Provides current-state diagnosis, P0/P1/P2 issue triage, and development direction.
---

# 출시 준비 점검 & 개발 방향 가이드

Tax Radar 앱의 빠른 출시를 위한 총괄 가이드. 현재 상태 진단, 이슈 우선순위, MVP 전략, 스토어 제출 체크리스트를 포함한다.

---

## 현재 출시 가능 여부

> **바로 출시 가능한가? → No.**
> P0 블로커 6건이 해결되어야 스토어 제출이 가능하다.
> P0 전부 해결 시 최소 출시 가능 상태(MVP)에 도달한다.

---

## 스킬 사용 프로토콜

이 스킬이 호출되면 다음 순서로 진행한다:

```
1. 이슈 현황 확인 — 아래 P0/P1/P2 목록에서 해결/미해결 상태 파악
2. 코드베이스 검증 — 각 이슈의 파일경로를 읽어 현재 수정 여부 확인
3. 진단 결과 출력 — 남은 블로커, 진행률, 다음 작업 권장
4. 작업 실행 — 사용자가 요청한 이슈 수정 진행
```

**중요:** 이슈 목록은 2026-02-21 기준 코드베이스 감사 결과다. 이후 수정된 항목은 코드를 직접 확인하여 상태를 갱신한다.

---

## P0 — 출시 차단 (반드시 수정)

이 항목이 하나라도 남아있으면 스토어 제출 불가 또는 사용자 데이터 유실 위험이 있다.

### P0-1. Hive 데이터 로드 시 에러 핸들링 없음

- **파일:** `lib/providers/business_provider.dart` — `_loadFromStorage()`
- **문제:** `fromJson()` 호출 전체에 try-catch가 없음. Hive 데이터 손상, 앱 업데이트로 스키마 불일치 시 `init()`에서 예외 발생 → 앱 실행 불가, 복구 경로 없음
- **추가 위험:** `MonthlySales.fromJson`, `MonthlyExpenses.fromJson`, `DeemedPurchase.fromJson`에서 `DateTime.parse()` 사용 (try 없음) — 잘못된 날짜 문자열 시 `FormatException` 크래시
- **수정 방향:**
  ```dart
  // _loadFromStorage 전체를 try-catch로 감싸기
  Future<void> _loadFromStorage() async {
    try {
      final box = Hive.box('taxRadar');
      // ... 기존 로드 로직
    } catch (e) {
      // 로드 실패 시 기본값으로 초기화 (데이터 유실보다 앱 실행이 중요)
      debugPrint('데이터 로드 실패, 기본값으로 초기화: $e');
      // 선택: 손상된 박스 클리어 후 재시작
    }
  }
  ```
  ```dart
  // fromJson의 DateTime.parse → DateTime.tryParse 변경
  yearMonth: DateTime.tryParse(json['yearMonth'] as String? ?? '')
      ?? DateTime(2000, 1, 1),
  ```

### P0-2. 데이터 초기화(리셋) 기능 미작동

- **파일:** `lib/screens/settings/settings_screen.dart` — 데이터 초기화 다이얼로그
- **문제:** 확인 버튼이 `context.go('/splash')`만 호출. `BusinessProvider`에 `resetAllData()` 메서드 자체가 없음. `onboardingComplete`가 true로 유지되어 splash가 즉시 `/radar`로 리다이렉트. 결과적으로 리셋이 전혀 작동하지 않음
- **수정 방향:**
  ```dart
  // BusinessProvider에 추가
  Future<void> resetAllData() async {
    final box = Hive.box('taxRadar');
    await box.clear();
    // 모든 상태를 기본값으로 복원
    _business = Business();
    _profile = UserProfile();
    _salesList = [];
    _expensesList = [];
    _deemedPurchases = [];
    _onboardingComplete = false;
    // ... 나머지 상태 초기화
    notifyListeners();
  }
  ```
  ```dart
  // settings_screen.dart 리셋 다이얼로그에서
  await context.read<BusinessProvider>().resetAllData();
  context.go('/splash');
  ```

### P0-3. 개인정보 처리방침 미구현

- **파일:** `lib/screens/settings/settings_screen.dart` — `// TODO: 개인정보 처리방침`
- **문제:** 탭 핸들러가 빈 함수. App Store/Play Store 모두 기능하는 개인정보 처리방침 링크 필수 (100% 로컬 앱이라도)
- **수정 방향:**
  - 웹에 개인정보 처리방침 페이지 호스팅 (GitHub Pages, Notion 공개 페이지 등)
  - `url_launcher` 패키지 추가하여 외부 브라우저로 열기
  - **또는** 앱 내 정적 텍스트 화면으로 구현 (네트워크 불필요)
- **처리방침 필수 포함 내용 (로컬 전용 앱):**
  - 수집하는 개인정보: 없음 (모든 데이터는 기기에만 저장)
  - 서버 전송: 없음
  - 제3자 제공: 없음
  - 데이터 삭제: 앱 삭제 시 자동 삭제 또는 설정에서 초기화

### P0-4. Android 릴리스 서명 미설정

- **파일:** `android/app/build.gradle.kts` — `signingConfig = signingConfigs.getByName("debug")`
- **문제:** 릴리스 빌드가 debug 키로 서명됨. Play Store 업로드 시 거부됨
- **수정 방향:**
  ```kotlin
  // android/app/build.gradle.kts
  signingConfigs {
      create("release") {
          storeFile = file(keystoreProperties["storeFile"] as String)
          storePassword = keystoreProperties["storePassword"] as String
          keyAlias = keystoreProperties["keyAlias"] as String
          keyPassword = keystoreProperties["keyPassword"] as String
      }
  }
  buildTypes {
      release {
          signingConfig = signingConfigs.getByName("release")
      }
  }
  ```
  - `key.properties` 파일 생성 (git에 포함하지 않을 것)
  - `keytool`로 릴리스 키스토어 생성

### P0-5. 앱 아이콘이 Flutter 기본 아이콘

- **파일:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `android/app/src/main/res/mipmap-*/`
- **문제:** 모든 아이콘이 파란색 Flutter 로고 (8-bit colormap). 스토어 리뷰에서 플레이스홀더 아트워크로 리젝 사유
- **수정 방향:**
  1. 1024x1024 브랜드 아이콘 원본 준비
  2. `flutter_launcher_icons` 패키지 사용하여 자동 생성:
     ```yaml
     # pubspec.yaml
     dev_dependencies:
       flutter_launcher_icons: ^0.14.3

     flutter_launcher_icons:
       android: true
       ios: true
       image_path: "assets/icon/app_icon.png"
     ```
  3. `dart run flutter_launcher_icons` 실행

### P0-6. google_fonts 런타임 폰트 다운로드

- **파일:** `lib/theme/app_typography.dart`, `lib/main.dart`
- **문제:** `google_fonts` 패키지가 첫 실행 시 네트워크에서 폰트 다운로드 시도. 오프라인 기기에서 시스템 기본 폰트로 폴백 → UI 불일치. "100% 로컬" 앱 콘셉트와 모순
- **수정 방향:**
  ```dart
  // main.dart — runApp() 전에 추가
  GoogleFonts.config.allowRuntimeFetching = false;
  ```
  ```yaml
  # pubspec.yaml — 폰트 로컬 번들링
  flutter:
    fonts:
      - family: NotoSansKR
        fonts:
          - asset: assets/fonts/NotoSansKR-Regular.ttf
          - asset: assets/fonts/NotoSansKR-Medium.ttf
            weight: 500
          - asset: assets/fonts/NotoSansKR-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/NotoSansKR-Bold.ttf
            weight: 700
      - family: Manrope
        fonts:
          - asset: assets/fonts/Manrope-Regular.ttf
          - asset: assets/fonts/Manrope-Medium.ttf
            weight: 500
          - asset: assets/fonts/Manrope-Bold.ttf
            weight: 700
          - asset: assets/fonts/Manrope-ExtraBold.ttf
            weight: 800
  ```
  - Google Fonts에서 `.ttf` 파일 다운로드하여 `assets/fonts/`에 배치
  - `app_typography.dart`에서 `GoogleFonts.notoSans()` → `TextStyle(fontFamily: 'NotoSansKR')` 전환
  - 또는 `GoogleFonts.notoSans()`를 유지하되, 로컬 번들 폰트를 자동 우선 사용하도록 설정

---

## P1 — 출시 전 권장 (UX 품질)

P1은 앱이 스토어에 올라갈 수는 있지만, 사용자 경험에 문제가 있는 항목이다.

### P1-1. Settings 사업자정보 수정 → 온보딩 플로우 진입 버그

- **파일:** `lib/screens/settings/settings_screen.dart` (line ~140), `lib/screens/onboarding/business_info_screen.dart`
- **문제:** "수정" 탭 → `context.push('/onboarding/business-info')` → "다음" 누르면 `context.go('/onboarding/first-sales')`로 이동. 사용자가 설정에서 사업자 유형만 바꾸려 했는데 온보딩 매출 입력으로 빠짐
- **수정 방향:** BusinessInfoScreen에 `isEditing` 파라미터 추가. 편집 모드일 때 "다음" 대신 "저장" 후 `context.pop()`

### P1-2. 매출입력 화면 기타현금매출 음수 가능

- **파일:** `lib/screens/data_input/sales_input_screen.dart` (line ~58)
- **문제:** `_otherCashSales = _totalSales - _cardSales - _cashReceiptSales` — 카드비율 + 현금영수증 비율이 100% 초과 시 음수. `FirstSalesScreen`은 `.clamp(0, total)` 적용하나 이 화면은 미적용
- **수정 방향:** `.clamp(0, _totalSales)` 적용

### P1-3. 경비입력 화면 월 전환 시 기존 데이터 미로드

- **파일:** `lib/screens/data_input/expense_input_screen.dart` (line ~113)
- **문제:** 월 탭 전환 시 `setState(() => _selectedMonth = month)` 만 호출. 해당 월에 기존 입력 데이터가 있어도 텍스트 필드에 로드되지 않음. 사용자가 빈 필드로 저장하면 기존 데이터 덮어쓰기
- **수정 방향:** 월 전환 시 `_loadExistingData()` 호출 추가 (매출입력 화면의 패턴 참고)

### P1-4. 알림벨 + 전체보기 버튼 no-op

- **파일:** `lib/screens/radar/radar_screen.dart` (line ~198, ~707)
- **문제:** 알림벨 아이콘에 빨간 점이 항상 표시되나 탭해도 아무 동작 없음. "전체보기" 버튼도 no-op. 사용자에게 고장난 앱 인상을 줌
- **수정 방향:**
  - **옵션 A (빠른):** 알림벨, 전체보기 버튼 제거
  - **옵션 B (유지):** 알림벨 → 세금 캘린더/일정 화면 연결, 전체보기 → `/data` 화면으로 이동

### P1-5. Settings 알림 토글 미연결

- **파일:** `lib/screens/settings/settings_screen.dart` (line ~16-17)
- **문제:** `_taxSeasonNotif`, `_monthlyInputNotif`가 `State` 로컬 변수. 화면 이동 시 초기화됨. 실제 알림 시스템 없음
- **수정 방향:**
  - **옵션 A (빠른):** 토글 UI 제거하고 "알림 기능은 추후 업데이트 예정" 문구
  - **옵션 B (유지):** `BusinessProvider`에 설정 저장 + `flutter_local_notifications` 연동

### P1-6. 앱 메타데이터 오류

- **파일들:**
  - `lib/screens/settings/settings_screen.dart` (line ~281): 저작권 `2024` → `2025` 수정
  - `lib/screens/settings/settings_screen.dart` (line ~263): 앱 버전 하드코딩 `'1.0.0'` → `package_info_plus` 사용 또는 빌드 시 주입
  - `android/app/src/main/AndroidManifest.xml`: `android:label="tax_radar"` → `"세금레이더"`
  - `ios/Runner/Info.plist`: `CFBundleName` = `"tax_radar"` → `"세금레이더"`

### P1-7. iOS 빌드 설정 정리

- **파일:** `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile`
- **문제:**
  - `CODE_SIGN_IDENTITY` = `"iPhone Developer"` (레거시) → `"Apple Distribution"` 권장
  - Podfile의 `platform :ios` 주석 처리됨 → 주석 해제
  - 가로 모드 지원 중이나 가로 레이아웃 없음 → 세로 고정 권장
- **수정 방향:** Xcode에서 Deployment Info 확인, 세로 전용 설정

---

## P2 — 출시 후 업데이트 (v1.1+)

출시를 늦추지 않아도 되는 항목. 업데이트 로드맵에 포함.

| # | 항목 | 영향도 | 비고 |
|---|------|--------|------|
| P2-1 | 온보딩 진행률 표시 (1/3, 2/3) | 낮음 | UX 개선 |
| P2-2 | 개별 월 데이터 삭제 기능 | 중간 | 현재 덮어쓰기만 가능 |
| P2-3 | 시뮬레이터 빈 상태 안내 문구 | 낮음 | 데이터 없을 때 0만~0만 표시 |
| P2-4 | 금융소득종합과세(금종세) 구현 | 중간 | `precision_tax_engine.dart` — 현재 무시됨 |
| P2-5 | 두 엔진 간 반올림 정책 통일 | 낮음 | 최대 10원 차이 |
| P2-6 | 종소세 계산 테스트 추가 | 중간 | `computeIncomeTaxBreakdown` 테스트 0건 |
| P2-7 | iOS Privacy Manifest 추가 | 중간 | iOS 17+ 권장사항 |
| P2-8 | Android 적응형 아이콘 | 낮음 | `ic_launcher_foreground/background` |
| P2-9 | `FirstResultScreen` 뒤로가기 버튼 | 낮음 | 현재 back 불가 |
| P2-10 | 카드비율 슬라이더 최솟값 50%→0% | 낮음 | 현금 위주 가게 대응 |
| P2-11 | 부모 부양 인원수 (bool→int) | 낮음 | 현재 1명 고정 |
| P2-12 | GoRouter redirect 가드 구현 | 낮음 | 딥링크 보호 |
| P2-13 | 실제 로컬 알림 구현 | 중간 | `flutter_local_notifications` |
| P2-14 | 스플래시 화면 커스텀 디자인 | 낮음 | 현재 빈 흰색 |

---

## MVP 출시 전략

### 핵심 원칙

> **"완벽한 앱"보다 "쓸 수 있는 앱"을 먼저 출시하라.**
> P0 수정 → P1 핵심 수정 → 출시 → P2 업데이트 사이클.

### 1차 출시에 반드시 포함할 기능

| 기능 | 현재 상태 | 비고 |
|------|----------|------|
| 부가세 예측 (반기별) | 완성 | 핵심 가치 |
| 종소세 예측 (연간) | 완성 | 핵심 가치 |
| 매출/경비/의제매입 입력 | 완성 | 데이터 입력 |
| 세금 상세 분석 화면 | 완성 | 분석 |
| 정확도 게이지 | 완성 | 차별화 요소 |
| 세금 캘린더 | 완성 | 실용 기능 |
| 온보딩 플로우 | 완성 | 첫인상 |

### 1차 출시에서 빼거나 숨길 기능

| 기능 | 이유 | 처리 방법 |
|------|------|----------|
| 알림벨 (레이더 상단) | 기능 미구현, 사용자 혼란 | UI에서 제거 |
| 전체보기 버튼 | no-op | UI에서 제거하거나 `/data`로 연결 |
| 알림 토글 (설정) | 실제 알림 시스템 없음 | "추후 업데이트 예정" 표시 또는 제거 |
| 금융소득종합과세 | precision engine에서 미구현 | 안내 문구로 한계 명시 |

### 출시 전 품질 기준

```
출시 가능 최소 기준 (모두 충족해야 함):
□ P0 블로커 6건 모두 해결
□ flutter analyze — 에러 0건
□ flutter test — 모든 테스트 통과
□ 온보딩 전체 플로우 수동 테스트 통과
□ 데이터 입력 → 세금 계산 → 상세 화면 플로우 수동 테스트 통과
□ 데이터 초기화 후 재시작 정상 작동
□ 앱 강제 종료 후 데이터 유지 확인
□ 오프라인 상태에서 전체 기능 정상 작동
```

---

## 스토어 제출 체크리스트

### Apple App Store

```
빌드 준비:
□ 커스텀 앱 아이콘 (1024x1024 PNG, RGB, 알파 없음)
□ iOS 앱 아이콘 세트 생성 (flutter_launcher_icons)
□ 스플래시 화면 커스텀 (최소 브랜드 로고)
□ Xcode에서 Bundle Identifier 확인
□ 릴리스 빌드 코드 사이닝 설정
□ IPHONEOS_DEPLOYMENT_TARGET 확인 (13.0+)
□ 세로 모드 전용 설정 (권장)

App Store Connect:
□ 앱 이름: "세금레이더" 또는 "세금레이더 - 자영업자 세금 예측"
□ 부제목: "음식점·카페 부가세 종소세 계산기"
□ 카테고리: Finance (금융)
□ 개인정보 처리방침 URL 등록
□ 연령 등급: 4+ (세금/금융 콘텐츠, 제한 없음)
□ 스크린샷: iPhone 6.7" (필수), 6.5" (필수), iPad (선택)
□ 앱 설명 (한국어): 핵심 기능 3-5줄 요약
□ 키워드: 세금, 부가세, 종소세, 자영업자, 음식점, 카페, 세금계산기
□ 앱 미리보기 영상 (선택사항)

데이터 수집 설문:
□ "데이터를 수집하지 않음" 선택 (100% 로컬 저장)
```

### Google Play Store

```
빌드 준비:
□ 릴리스 키스토어 생성 (keytool)
□ key.properties 설정 (.gitignore에 추가)
□ build.gradle.kts 릴리스 서명 설정
□ 커스텀 앱 아이콘 (512x512 PNG)
□ Android 앱 아이콘 세트 생성 (flutter_launcher_icons)
□ AndroidManifest.xml android:label 수정
□ 릴리스 APK/AAB 빌드 테스트: flutter build appbundle --release

Play Console:
□ 앱 이름: "세금레이더 - 자영업자 세금 예측"
□ 짧은 설명 (80자): "음식점·카페 사장님을 위한 부가세·종소세 예측 앱"
□ 전체 설명 (한국어): 핵심 기능 + 특징 상세 설명
□ 카테고리: Finance (금융)
□ 개인정보 처리방침 URL 등록
□ 콘텐츠 등급 설문: IARC 등급 "전체이용가"
□ 스크린샷: 최소 2장 (휴대전화), 권장 4-8장
□ 그래픽 이미지: 1024x500 (스토어 배너)
□ 아이콘: 512x512 PNG

데이터 보안 섹션:
□ "데이터를 수집하거나 공유하지 않음" 선택
□ 데이터 암호화: 기기 저장 (Hive, 앱 샌드박스)
□ 데이터 삭제 요청 방법: 앱 내 초기화 또는 앱 삭제
```

---

## 출시 후 로드맵

### v1.1 — 안정화 + UX 개선 (출시 후 2-4주)

- P2-2: 월별 데이터 삭제 기능
- P2-3: 시뮬레이터 빈 상태 안내
- P2-6: 종소세 테스트 커버리지 확충
- P2-13: 세금 시즌 로컬 알림 (납부기한 D-7, D-3, D-day)
- 사용자 피드백 기반 버그 수정

### v1.2 — 기능 확장 (출시 후 1-2개월)

- P2-4: 금융소득종합과세 대응
- P2-11: 부양가족 인원수 세분화
- 간이과세자 지원 강화
- 전자세금계산서 연동 검토 (홈택스 API)

### v2.0 — 확장 (출시 후 3-6개월)

- 다중 사업장 지원
- 연도별 데이터 비교
- 세금 신고서 초안 생성
- 위젯 (홈 화면 세금 D-day)

---

## 작업 순서 권장

빠른 출시를 위한 권장 작업 순서:

```
Phase 1 — P0 블로커 해결 (최우선)
  1. P0-1: _loadFromStorage 에러 핸들링 (가장 위험)
  2. P0-2: 데이터 초기화 기능 구현
  3. P0-6: google_fonts 로컬 번들링
  4. P0-3: 개인정보 처리방침 (앱 내 정적 화면)

Phase 2 — P1 핵심 수정
  5. P1-4: 알림벨/전체보기 제거 또는 연결
  6. P1-5: 알림 토글 제거 또는 "추후 업데이트" 표시
  7. P1-2: 기타현금매출 음수 방지
  8. P1-3: 경비입력 월 전환 데이터 로드
  9. P1-6: 앱 메타데이터 수정 (라벨, 저작권, 버전)

Phase 3 — 스토어 준비 (병렬 가능)
  10. P0-5: 앱 아이콘 디자인 + 적용
  11. P0-4: Android 릴리스 서명 설정
  12. P1-7: iOS 빌드 설정
  13. 스토어 메타데이터 작성 (설명, 스크린샷, 키워드)
  14. 스플래시 화면 커스텀 (선택)

Phase 4 — 최종 검증
  15. flutter analyze + flutter test 통과
  16. 전체 플로우 수동 테스트 (온보딩→입력→예측→상세→설정→리셋)
  17. 오프라인 테스트
  18. 릴리스 빌드 실기기 테스트
```

---

## 진단 출력 형식

출시 점검 실행 시 다음 형식으로 결과를 출력한다:

```markdown
## 출시 준비 진단 결과

**진단 일시:** YYYY-MM-DD
**출시 가능 여부:** [가능 / 불가 — N건 블로커]

### P0 블로커 현황 (N/6 해결)
- [x] P0-1: Hive 에러 핸들링
- [ ] P0-2: 데이터 초기화
- ...

### P1 권장 수정 (N/7 해결)
- ...

### 다음 작업 권장
> "P0-X를 먼저 수정하세요. 예상 작업: [설명]"

### 출시까지 남은 예상 항목
- P0: N건
- P1 필수: N건
- 스토어 준비: N건
```

---

## 점검 항목 검증 방법

각 P0/P1 수정 후 다음을 확인한다:

```bash
# 정적 분석
flutter analyze

# 기존 테스트 통과
flutter test

# 릴리스 빌드 확인 (iOS)
flutter build ios --release --no-codesign

# 릴리스 빌드 확인 (Android)
flutter build appbundle --release
```

수동 테스트 시나리오:

```
□ 앱 첫 설치 → 온보딩 → 매출 입력 → 레이더 확인
□ 앱 강제 종료 → 재시작 → 데이터 유지 확인
□ 설정 → 데이터 초기화 → 온보딩 재시작 확인
□ 비행기 모드 → 앱 실행 → 모든 기능 정상 작동
□ 매출 0원 입력 → 세금 계산 → 상세 화면 → 크래시 없음
□ 매출 99억 입력 → UI 오버플로우 없음
```
