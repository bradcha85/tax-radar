# iOS App Store 출시 가이드 (Fastlane)

> 세금레이더 iOS 앱을 Fastlane으로 App Store에 제출하기 위한 전체 작업 목록.
> 현재 프로젝트 상태를 기반으로 작성됨 (2026-02-22).

---

## 현재 상태 진단

| 항목 | 현재 값 | 필요 조치 |
|------|--------|----------|
| Bundle ID | `com.taxradar.taxRadar` | 확인 (변경 시 Apple Developer에서 재등록) |
| CFBundleDisplayName | `Tax Radar` | `세금레이더`로 변경 |
| CFBundleName | `tax_radar` | `세금레이더`로 변경 |
| 앱 버전 | `1.0.0+1` | OK |
| Deployment Target | iOS 13.0 | OK |
| 코드 사이닝 | Automatic, Team `WDS47KFKVK` | 배포용 설정 필요 |
| CODE_SIGN_IDENTITY | `iPhone Developer` (개발용) | `Apple Distribution`으로 변경 |
| 세로/가로 모드 | 세로+가로 모두 지원 | 세로 전용으로 변경 권장 |
| Podfile platform | 주석 처리됨 | 주석 해제 |
| Fastlane | 미설치, 미초기화 | 설치 + 초기화 필요 |
| 앱 아이콘 | Flutter 기본 아이콘 | 커스텀 아이콘 필요 |

---

## 전체 작업 순서

```
Phase 1 — 사전 준비 (Apple 계정 + 에셋)
Phase 2 — Xcode 프로젝트 설정
Phase 3 — Fastlane 설치 및 초기화
Phase 4 — 메타데이터 파일 작성
Phase 5 — 스크린샷 준비
Phase 6 — 빌드 및 테스트
Phase 7 — 제출
```

---

## Phase 1 — 사전 준비

### 1-1. Apple Developer 계정 확인

```
□ Apple Developer Program 가입 완료 (연 $99)
  → https://developer.apple.com/programs/
□ App Store Connect 접근 가능
  → https://appstoreconnect.apple.com
□ 팀 ID 확인: WDS47KFKVK (이미 설정됨)
```

### 1-2. App Store Connect에서 앱 등록

```
1. App Store Connect → "나의 앱" → "+" → "신규 앱"
2. 아래 정보 입력:

   플랫폼: iOS
   이름: 세금레이더
   기본 언어: 한국어
   번들 ID: com.taxradar.taxRadar (Xcode에서 등록된 것 선택)
   SKU: taxradar-ios-001 (내부 식별용, 아무 값이나 가능)

3. "생성" 클릭
```

> 번들 ID가 선택 목록에 없다면:
> Apple Developer → Certificates, Identifiers & Profiles → Identifiers → "+"
> → App IDs → `com.taxradar.taxRadar` 등록

### 1-3. 앱 아이콘 준비

```
□ 1024x1024 PNG 원본 아이콘 제작
  - sRGB 색상 공간
  - 알파(투명도) 없음
  - 모서리 둥글게 하지 말 것 (시스템이 자동 적용)

□ flutter_launcher_icons로 모든 사이즈 자동 생성:

  # pubspec.yaml에 추가
  dev_dependencies:
    flutter_launcher_icons: ^0.14.3

  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/icon/app_icon.png"
    remove_alpha_ios: true

  # 실행
  dart run flutter_launcher_icons
```

### 1-4. 개인정보 처리방침 URL 준비

```
□ 웹에 개인정보 처리방침 페이지 호스팅
  - GitHub Pages, Notion 공개 페이지, 또는 개인 웹사이트
  - 앱 내에 이미 정적 화면이 구현되어 있지만, App Store Connect에는 URL이 필요

□ URL 예시: https://taxradar.github.io/privacy-policy
```

### 1-5. 지원 URL 준비

```
□ 사용자가 문의할 수 있는 페이지 URL
  - 이메일만 적힌 간단한 페이지도 가능
  - 또는 GitHub Issues 페이지
  - URL 예시: https://taxradar.github.io/support
```

---

## Phase 2 — Xcode 프로젝트 설정

### 2-1. Info.plist 수정

`ios/Runner/Info.plist`에서 다음을 변경:

```xml
<!-- 변경 전 -->
<key>CFBundleDisplayName</key>
<string>Tax Radar</string>
<key>CFBundleName</key>
<string>tax_radar</string>

<!-- 변경 후 -->
<key>CFBundleDisplayName</key>
<string>세금레이더</string>
<key>CFBundleName</key>
<string>세금레이더</string>
```

### 2-2. 세로 모드 전용 설정

`ios/Runner/Info.plist`에서 가로 모드 제거:

```xml
<!-- 변경 후: iPhone 세로 전용 -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>

<!-- iPad도 세로 전용 (가로 레이아웃이 없으므로) -->
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### 2-3. Podfile 플랫폼 주석 해제

`ios/Podfile` 첫 줄:

```ruby
# 변경 전
# platform :ios, '13.0'

# 변경 후
platform :ios, '13.0'
```

변경 후 실행:

```bash
cd ios && pod install && cd ..
```

### 2-4. 코드 사이닝 설정

Xcode에서 설정하는 것이 가장 안전하다:

```
1. Xcode에서 ios/Runner.xcworkspace 열기
2. Runner 타겟 선택 → Signing & Capabilities 탭

   □ Automatically manage signing: 체크
   □ Team: 본인 Apple Developer 팀 선택 (WDS47KFKVK)
   □ Bundle Identifier: com.taxradar.taxRadar

   자동 관리가 활성화되면 Xcode가 알아서:
   - Distribution 인증서 생성/선택
   - Provisioning Profile 생성
   - 코드 사이닝 설정
```

> **수동 사이닝을 원하는 경우** (CI/CD용):
> Fastlane `match`를 사용하여 인증서/프로파일 관리 가능 (아래 Phase 3 참고)

### 2-5. 릴리스 빌드 확인

```bash
# 코드 사이닝 없이 빌드 테스트
flutter build ios --release --no-codesign

# 성공하면 → Xcode에서 코드 사이닝 포함 빌드
flutter build ipa --release
```

---

## Phase 3 — Fastlane 설치 및 초기화

### 3-1. Fastlane 설치

```bash
# Homebrew로 설치 (권장)
brew install fastlane

# 또는 gem으로 설치
sudo gem install fastlane -NV

# 설치 확인
fastlane --version
```

### 3-2. Fastlane 초기화

```bash
cd /Users/bccha/Projects/tax-radar/ios
fastlane init
```

초기화 시 선택지:

```
1. 📸 Automate screenshots
2. 👩‍✈️ Automate beta distribution to TestFlight
3. 🚀 Automate App Store distribution
4. 🛠 Manual setup

→ 4번 (Manual setup) 선택
```

초기화 후 생성되는 파일:

```
ios/
├── fastlane/
│   ├── Appfile
│   ├── Fastfile
│   └── (metadata/ — deliver init 후 생성)
├── Gemfile
└── Gemfile.lock
```

### 3-3. Appfile 작성

`ios/fastlane/Appfile`:

```ruby
app_identifier("com.taxradar.taxRadar")
apple_id("본인_애플_아이디@icloud.com")

itc_team_id("App Store Connect 팀 ID")
team_id("WDS47KFKVK")
```

> `itc_team_id` 확인 방법:
> ```bash
> cd ios && fastlane deliver init
> # 팀이 여러 개면 선택 화면에서 ID가 표시됨
> ```

### 3-4. Fastfile 작성

`ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do

  desc "메타데이터 + 스크린샷만 업로드"
  lane :metadata do
    deliver(
      skip_binary_upload: true,
      skip_screenshots: false,
      force: true,
      metadata_path: "./fastlane/metadata",
      screenshots_path: "./fastlane/screenshots"
    )
  end

  desc "릴리스 빌드 생성"
  lane :build do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      output_directory: "../build/ios/ipa",
      output_name: "TaxRadar.ipa"
    )
  end

  desc "TestFlight 업로드"
  lane :beta do
    build
    upload_to_testflight(
      ipa: "../build/ios/ipa/TaxRadar.ipa",
      skip_waiting_for_build_processing: true,
      changelog: "내부 테스트 빌드"
    )
  end

  desc "App Store 심사 제출"
  lane :release do
    build
    deliver(
      ipa: "../build/ios/ipa/TaxRadar.ipa",
      submit_for_review: true,
      automatic_release: false,
      force: true,
      submission_information: {
        add_id_info_uses_idfa: false
      }
    )
  end

end
```

### 3-5. 메타데이터 디렉토리 생성

```bash
cd /Users/bccha/Projects/tax-radar/ios
fastlane deliver init
```

> 이미 App Store Connect에 앱이 등록되어 있으면 기존 메타데이터를 다운로드.
> 아직 등록 전이면 빈 디렉토리 구조가 생성됨.

---

## Phase 4 — 메타데이터 파일 작성

### 4-1. 디렉토리 구조

`ios/fastlane/metadata/ko/` 아래에 각 파일을 생성한다:

```
ios/fastlane/metadata/
├── ko/
│   ├── name.txt
│   ├── subtitle.txt
│   ├── description.txt
│   ├── keywords.txt
│   ├── promotional_text.txt
│   ├── release_notes.txt
│   ├── support_url.txt
│   ├── marketing_url.txt        (선택)
│   └── privacy_url.txt
├── copyright.txt
├── primary_category.txt
├── secondary_category.txt       (선택)
└── review_information/
    ├── first_name.txt
    ├── last_name.txt
    ├── phone_number.txt
    ├── email_address.txt
    ├── demo_user.txt             (비워둠)
    ├── demo_password.txt         (비워둠)
    └── notes.txt
```

### 4-2. 각 파일 내용 (복사하여 생성)

**`metadata/ko/name.txt`**
```
세금레이더
```

**`metadata/ko/subtitle.txt`**
```
음식점·카페 부가세·종소세 예측
```

**`metadata/ko/keywords.txt`**
```
부가세,종소세,자영업자,음식점세금,카페세금,의제매입,세금계산기,절세,사장님,부가가치세,세금예측
```

**`metadata/ko/promotional_text.txt`**
```
다음 세금, 미리 알고 준비하세요. 매출만 입력하면 부가세·종소세 예상 납부액을 즉시 확인할 수 있습니다. 의제매입세액공제 자동 계산으로 절세 효과까지 한눈에.
```

**`metadata/ko/description.txt`**
```
부가세 신고일이 다가올 때마다 얼마나 나올지 몰라 불안하셨나요?

세금레이더는 음식점·카페 사장님을 위한 세금 예측 앱입니다.
매출만 입력하면 부가세와 종합소득세 예상 납부액을 바로 확인할 수 있습니다.

━━━━━━━━━━━━━━━━━━━━━

▶ 부가세·종소세 예상액 즉시 확인
매출 금액만 입력하면 다음 부가세 신고 때 납부할 금액을 바로 보여드립니다. 종합소득세 예상액도 함께 확인하세요.

▶ 의제매입세액공제 자동 계산
음식점 사장님이 놓치기 쉬운 의제매입세액공제를 자동으로 계산합니다. 면세 식재료 매입액을 입력하면 얼마나 절세되는지 바로 확인할 수 있어요.

▶ 시뮬레이터로 미리 예측
"매출이 늘면 세금은 얼마나 늘까?" 슬라이더를 움직여 다양한 시나리오를 미리 확인해보세요.

▶ 세금 캘린더
부가세, 종합소득세 납부 기한을 놓치지 않도록 D-day를 알려드립니다.

▶ 정밀 종소세 계산
인적공제, 노란우산공제까지 반영한 상세한 종합소득세 예측을 제공합니다.

▶ 용어사전
부가가치세, 의제매입, 과세표준... 어려운 세금 용어를 쉽게 풀어드립니다.

━━━━━━━━━━━━━━━━━━━━━

✓ 100% 오프라인 — 인터넷 없이도 모든 기능이 작동합니다
✓ 개인정보 외부 전송 없음 — 입력한 데이터는 기기에만 저장됩니다
✓ 완전 무료 — 숨겨진 비용이나 인앱 결제가 없습니다

━━━━━━━━━━━━━━━━━━━━━

세금레이더는 세금 '신고'가 아닌 세금 '예측' 앱입니다.
신고 시즌이 아닐 때도 수시로 확인하며 미리 준비하세요.

문의: taxradar.app@gmail.com
```

**`metadata/ko/release_notes.txt`**
```
세금레이더 첫 출시!

• 부가세·종소세 예상 납부액 계산
• 매출/경비/의제매입 월별 입력
• 세금 상세 분석 (항목별 분해)
• 매출 변동 시뮬레이터
• 정밀 종소세 계산 (인적공제, 노란우산)
• 세금 캘린더 (납부기한 D-day)
• 세금 용어사전

100% 오프라인 · 완전 무료 · 개인정보 수집 없음
```

**`metadata/ko/support_url.txt`**
```
https://taxradar.github.io/support
```

**`metadata/ko/privacy_url.txt`**
```
https://taxradar.github.io/privacy-policy
```

**`metadata/copyright.txt`**
```
© 2025 세금레이더
```

**`metadata/primary_category.txt`**
```
Finance
```

**`metadata/review_information/first_name.txt`**
```
[본인 이름]
```

**`metadata/review_information/last_name.txt`**
```
[본인 성]
```

**`metadata/review_information/phone_number.txt`**
```
[본인 전화번호]
```

**`metadata/review_information/email_address.txt`**
```
[본인 이메일]
```

**`metadata/review_information/notes.txt`**
```
이 앱은 로그인이 필요하지 않습니다.
앱 실행 시 온보딩 화면이 나타납니다.
업종(음식점/카페)을 선택하고 매출 금액을 입력하면 세금 예상액을 확인할 수 있습니다.
모든 데이터는 기기에만 저장되며 네트워크 호출은 없습니다.
```

---

## Phase 5 — 스크린샷 준비

### 5-1. 스크린샷 촬영

```bash
# iPhone 16 Pro Max 시뮬레이터 실행
open -a Simulator
# Simulator → File → Open Simulator → iPhone 16 Pro Max

# 앱 실행
flutter run -d "iPhone 16 Pro Max"
```

### 5-2. 앱 데이터 세팅

스크린샷용으로 보기 좋은 데이터를 입력:

```
온보딩 완료 후:
  업종: 한식 일반 음식점
  과세유형: 일반과세자
  월 매출: 5,000만원
  카드비율: 80%

추가 입력:
  경비: 500만원 (직원 인건비 300만 + 임대료 200만)
  의제매입: 1,500만원
```

### 5-3. 촬영할 화면 5장

시뮬레이터에서 `Cmd+S`로 스크린샷 저장 (자동으로 올바른 해상도):

| # | 화면 | 파일명 | 해상도 |
|---|------|--------|--------|
| 1 | 레이더 메인 (부가세 탭) | `01_radar.png` | 1260x2736 |
| 2 | 부가세 상세 분석 | `02_vat_detail.png` | 1260x2736 |
| 3 | 데이터 입력 탭 | `03_data_input.png` | 1260x2736 |
| 4 | 레이더 메인 (캘린더 영역) | `04_calendar.png` | 1260x2736 |
| 5 | 시뮬레이터 | `05_simulator.png` | 1260x2736 |

### 5-4. 스크린샷에 문구 추가 (권장)

Figma 또는 Canva에서 작업:

```
템플릿 사이즈: 1260 x 2736 px

레이아웃:
  ┌──────────────────────┐
  │                      │
  │    홍보 문구 (40pt+)  │  ← 상단 1/3 (912px)
  │    본고딕/Pretendard  │
  │                      │
  ├──────────────────────┤
  │                      │
  │    앱 스크린샷        │  ← 하단 2/3 (1824px)
  │    (디바이스 프레임    │
  │     안에 삽입)        │
  │                      │
  └──────────────────────┘

  배경: #2563EB → #1E40AF 그라데이션
  문구 색상: 흰색
```

| # | 문구 |
|---|------|
| 1 | **다음 부가세, 미리 확인하세요** |
| 2 | **면세 식재료로 부가세 절감** |
| 3 | **입력할수록 정확해져요** |
| 4 | **납부 기한, 놓치지 마세요** |
| 5 | **매출이 늘면 세금은?** |

### 5-5. 스크린샷 배치

```bash
# Fastlane 스크린샷 디렉토리 생성
mkdir -p ios/fastlane/screenshots/ko

# 파일 복사 (완성된 스크린샷을 여기에 넣기)
# 파일명 규칙: 아무 이름이나 가능, 해상도로 디바이스 자동 판별
cp 01_radar.png      ios/fastlane/screenshots/ko/01_radar.png
cp 02_vat_detail.png ios/fastlane/screenshots/ko/02_vat_detail.png
cp 03_data_input.png ios/fastlane/screenshots/ko/03_data_input.png
cp 04_calendar.png   ios/fastlane/screenshots/ko/04_calendar.png
cp 05_simulator.png  ios/fastlane/screenshots/ko/05_simulator.png
```

### 5-6. 스크린샷 검증

```
□ 포맷: PNG 또는 JPEG
□ 색상 공간: sRGB (CMYK 불가)
□ 투명도: 없음 (알파 채널 없음)
□ 해상도: 정확히 1260x2736 (iPhone 6.9")
□ 장수: 1~10장
□ 개인정보: 실제 전화번호, 이름 등이 보이지 않는지 확인
```

---

## Phase 6 — 빌드 및 테스트

### 6-1. 최종 코드 점검

```bash
# 정적 분석
flutter analyze

# 테스트
flutter test

# 둘 다 통과해야 진행
```

### 6-2. 릴리스 빌드

```bash
# 의존성 정리
flutter clean && flutter pub get

# iOS 릴리스 빌드 (IPA 생성)
flutter build ipa --release
```

빌드 성공 시 출력:

```
Built /Users/bccha/Projects/tax-radar/build/ios/ipa/tax_radar.ipa
```

> 빌드 실패 시 확인할 것:
> - Xcode에서 Runner.xcworkspace 열고 Signing & Capabilities 확인
> - `pod install` 재실행
> - Xcode 버전이 최신인지 확인

### 6-3. 실기기 테스트

```bash
# 실제 iPhone 연결 후
flutter run --release -d "본인 아이폰 이름"
```

테스트 시나리오:

```
□ 앱 첫 설치 → 온보딩 전체 플로우
□ 매출 입력 → 부가세 예측 → 상세 화면
□ 경비/의제매입 입력 → 정확도 변화
□ 시뮬레이터 슬라이더 조작
□ 세금 캘린더 날짜 탐색
□ 용어사전 검색 + 즐겨찾기
□ 설정 → 데이터 초기화 → 온보딩 재시작
□ 앱 강제 종료 → 재시작 → 데이터 유지
□ 비행기 모드에서 전체 기능 정상 작동
□ 큰 금액 입력 (99억) → UI 오버플로우 없음
□ 매출 0원 → 크래시 없음
```

### 6-4. TestFlight 배포 (선택)

```bash
cd ios
fastlane beta
```

> TestFlight 업로드 후:
> - App Store Connect → TestFlight 탭에서 빌드 처리 대기 (~10분)
> - 내부 테스터 추가 (본인 + 지인)
> - 테스트 후 피드백 반영

---

## Phase 7 — 제출

### 7-1. App Store Connect 설정 (Fastlane 불가 항목)

Fastlane으로 자동화할 수 없어 **웹에서 직접 설정**해야 하는 항목:

```
App Store Connect (https://appstoreconnect.apple.com) 에서:

1. 앱 개인정보 보호 (Privacy Nutrition Label)
   □ "나의 앱" → 세금레이더 → "앱 개인정보 보호" 탭
   □ "시작하기" 클릭
   □ "데이터를 수집합니까?" → "아니요" 선택
   □ "게시" 클릭

2. 연령 등급
   □ "나의 앱" → 세금레이더 → "가격 및 사용 가능 여부" 또는 "일반 정보"
   □ 연령 등급 설문 작성
   □ 모든 항목 "없음" / "아니요" 선택
   □ 결과: 4+

3. 가격
   □ "가격 및 사용 가능 여부" → 무료 선택

4. 사용 가능한 지역
   □ 기본값: 전 세계 (175개국)
   □ 또는 한국만 선택 (초기 출시 시)
```

### 7-2. Fastlane으로 메타데이터 업로드

```bash
cd /Users/bccha/Projects/tax-radar/ios

# 메타데이터 + 스크린샷만 먼저 업로드 (빌드 없이)
fastlane metadata
```

업로드 후 App Store Connect에서 확인:

```
□ 앱 이름: 세금레이더
□ 부제목: 음식점·카페 부가세·종소세 예측
□ 설명: 전체 내용 정상 표시
□ 키워드: 등록 확인
□ 스크린샷: 5장 정상 표시
□ 출시 노트: 내용 확인
□ 지원 URL: 링크 작동
□ 개인정보 처리방침 URL: 링크 작동
```

### 7-3. App Store 심사 제출

모든 것이 준비되면:

```bash
cd /Users/bccha/Projects/tax-radar/ios

# 빌드 + 제출 (한 번에)
fastlane release
```

또는 단계별로:

```bash
# 1단계: 빌드만
fastlane build

# 2단계: 빌드 확인 후 수동 제출
#   App Store Connect → 빌드 선택 → "심사를 위해 제출"
```

### 7-4. 심사 대기

```
평균 심사 기간: 24~48시간 (주말 제외)
상태 확인: App Store Connect → 나의 앱 → 세금레이더

심사 상태 흐름:
  제출 대기 → 심사 중 → 심사 완료 (승인 또는 거부)

승인 시:
  □ "자동 출시" 설정이면 즉시 App Store에 게시
  □ "수동 출시" 설정이면 직접 "이 버전 출시" 클릭
```

---

## 심사 거부 시 대응

### 흔한 거부 사유와 대응

| 거부 사유 | 대응 |
|----------|------|
| **Guideline 2.1 — 앱 크래시** | 크래시 로그 확인, 해당 기기에서 테스트 |
| **Guideline 2.3 — 정확한 메타데이터** | 스크린샷이 실제 앱과 일치하는지 확인 |
| **Guideline 4.2 — 최소 기능** | "세금 계산기와 차별점" 설명 추가 (Resolution Center) |
| **Guideline 5.1.1 — 개인정보** | 처리방침 URL 작동 확인, 라벨 정확한지 확인 |
| **디자인 스팸** | 앱 이름에 키워드 넣지 말 것 |

### Resolution Center 답변 템플릿

```
안녕하세요,

세금레이더는 단순 세금 계산기가 아닌, 음식점·카페 자영업자를 위한
연중 세금 예측 도구입니다.

주요 차별점:
1. 의제매입세액공제 자동 계산 (음식점 특화)
2. 매출 변동 시뮬레이터 (what-if 분석)
3. 부가세/종소세 동시 예측
4. 정확도 게이지 (데이터 완성도 시각화)
5. 정밀 종소세 계산 (인적공제, 노란우산공제)

100% 오프라인으로 작동하며, 개인정보를 수집하지 않습니다.

감사합니다.
```

---

## 전체 커맨드 요약

```bash
# === Phase 2: Xcode 설정 ===
cd /Users/bccha/Projects/tax-radar/ios && pod install && cd ..

# === Phase 3: Fastlane 설치 ===
brew install fastlane
cd ios && fastlane init    # 4번(Manual) 선택
fastlane deliver init      # 메타데이터 디렉토리 생성

# === Phase 4: 메타데이터 작성 ===
# metadata/ko/ 아래 파일들을 위 내용대로 생성

# === Phase 5: 스크린샷 ===
mkdir -p fastlane/screenshots/ko
# 스크린샷 파일 복사

# === Phase 6: 빌드 ===
cd /Users/bccha/Projects/tax-radar
flutter clean && flutter pub get
flutter analyze
flutter test
flutter build ipa --release

# === Phase 7: 제출 ===
cd ios
fastlane metadata          # 메타데이터 먼저 업로드
fastlane beta              # TestFlight 테스트 (선택)
fastlane release           # App Store 제출
```

---

## 체크리스트 (최종 요약)

```
Phase 1 — 사전 준비
  □ Apple Developer Program 가입
  □ App Store Connect에 앱 등록
  □ 앱 아이콘 1024x1024 제작 + flutter_launcher_icons 실행
  □ 개인정보 처리방침 URL 호스팅
  □ 지원 URL 준비

Phase 2 — Xcode 설정
  □ Info.plist: CFBundleDisplayName → "세금레이더"
  □ Info.plist: CFBundleName → "세금레이더"
  □ Info.plist: 세로 모드 전용
  □ Podfile: platform 주석 해제
  □ Xcode 코드 사이닝 설정

Phase 3 — Fastlane
  □ Fastlane 설치
  □ fastlane init (Manual)
  □ Appfile 작성
  □ Fastfile 작성
  □ fastlane deliver init

Phase 4 — 메타데이터
  □ name.txt, subtitle.txt, keywords.txt
  □ description.txt, promotional_text.txt
  □ release_notes.txt
  □ privacy_url.txt, support_url.txt
  □ copyright.txt, primary_category.txt
  □ review_information/ 작성

Phase 5 — 스크린샷
  □ iPhone 16 Pro Max 시뮬레이터에서 5장 촬영
  □ 문구 추가 (Figma/Canva)
  □ 1260x2736, sRGB, 알파 없음 확인
  □ screenshots/ko/ 에 배치

Phase 6 — 빌드
  □ flutter analyze 통과
  □ flutter test 통과
  □ flutter build ipa --release 성공
  □ 실기기 테스트 완료

Phase 7 — 제출
  □ App Store Connect: 개인정보 라벨 설정
  □ App Store Connect: 연령 등급 설정
  □ App Store Connect: 가격 (무료) 설정
  □ fastlane metadata 업로드
  □ fastlane release 또는 수동 제출
  □ 심사 통과 → 출시!
```
