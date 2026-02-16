# 세금 레이더 (Tax Radar)

음식점 자영업자를 위한 부가세·종소세 예측 앱

## 개요

회원가입 없이, 서버 없이, 매출 정보만 입력하면 세금 예상 범위를 알려주는 **로컬 전용 앱**입니다.
모든 데이터는 사용자의 기기에만 저장되며, 개인정보 유출 걱정이 없습니다.

```
[입력]                    [계산]              [출력]
월 매출액 (숫자)     →                    → 부가세 예상 범위
카드 비율 (슬라이더)  →   로컬 산수        → 종소세 예상 범위
면세 식재료 (숫자)   →                    → 정확도 게이지
부양가족 수 (선택)   →                    → 날씨 아이콘
```

---

## 기술 스택

| 영역 | 기술 | 버전 |
|---|---|---|
| 프레임워크 | Flutter (Dart) | SDK ^3.10.7 |
| 상태관리 | Provider | ^6.1.2 |
| 라우팅 | go_router | ^14.8.1 |
| 로컬 저장소 | Hive + hive_flutter | ^2.2.3 / ^1.1.0 |
| 포맷팅 | intl | ^0.20.2 |
| 폰트 | Google Fonts (Noto Sans) | ^6.2.1 |
| 서버 | **없음** (완전 로컬) | - |

---

## 아키텍처

### 설계 원칙

- **서버 제로**: 모든 계산과 저장이 기기 내에서 완결
- **회원가입 제로**: 설치 즉시 사용 가능
- **개인정보 안전**: 데이터가 기기 밖으로 나가지 않음
- **최소 입력**: 월 매출액 + 카드 비율만으로 예측 시작 가능

### 데이터 흐름

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│   Screens (입력 화면들)  →  Widgets (공통 위젯)           │
└──────────────────────────┬──────────────────────────────┘
                           │ Provider.of<BusinessProvider>
┌──────────────────────────▼──────────────────────────────┐
│                  BusinessProvider                        │
│   상태 관리 + Hive 영속성 + 계산된 속성 (getter)         │
│                                                         │
│   addSales() ──→ _salesList 업데이트 ──→ _saveToStorage()│
│   vatPrediction (getter) ──→ TaxCalculator.calculateVat()│
└──────────────────────────┬──────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   TaxCalculator      Formatters      Hive Box
   (순수 계산)        (포맷팅)       (영구 저장)
```

### 영속성 (Hive)

```
앱 시작 → Hive.initFlutter() → provider.init() → Hive box 열기 → _loadFromStorage()
데이터 변경 → notifyListeners() → _saveToStorage() → Hive box에 JSON Map 저장
```

- 저장소: 단일 Hive box `'taxRadar'`
- 직렬화: 각 모델의 `toJson()` / `fromJson()` 사용
- DateTime은 ISO 8601 문자열로 저장

---

## 화면 구성

### 전체 흐름

```
Splash ─┬─ (온보딩 미완료) ─→ 가치 제안 → 사업장 정보 → 첫 매출 → 첫 결과
        │
        └─ (온보딩 완료) ───→ 메인 Shell (하단 탭)
                              ├── /radar     레이더 (대시보드)
                              ├── /data      자료함
                              └── /settings  설정
```

### 화면별 상세

#### 1. Splash (`/splash`)
- 2초 대기 후 `onboardingComplete` 상태에 따라 분기
- 온보딩 완료 시 → `/radar`, 미완료 시 → `/onboarding/value`

#### 2. 온보딩 (최초 1회)

| 순서 | 경로 | 화면 | 입력 항목 |
|---|---|---|---|
| 1 | `/onboarding/value` | 가치 제안 | 없음 (소개 화면) |
| 2 | `/onboarding/business-info` | 사업장 정보 | 업종, 과세유형, VAT 포함 여부 |
| 3 | `/onboarding/first-sales` | 첫 매출 입력 | 프리셋 금액 선택, 월 선택, 카드 비율 슬라이더 |
| 4 | `/onboarding/first-result` | 첫 결과 | 부가세 예상 범위 + 정확도 표시 |

#### 3. 메인 - 레이더 (`/radar`)
- 부가세·종소세 예상 카드 (TaxCard)
- D-day 표시 (다음 납부 기한까지)
- 세금 시즌 배너 (납부일 30일 이내일 때 표시)
- 정확도 게이지 (매출/지출/의제매입/최신성 4항목)
- 세금 캘린더 카드
- 시뮬레이터 진입 버튼

#### 4. 메인 - 자료함 (`/data`)
- 전체 정확도 프로그레스 바
- 4개 데이터 카테고리 카드:
  - 매출 → `/data/sales-input`
  - 지출 → `/data/expense-input`
  - 의제매입 → `/data/deemed-purchase`
  - 과거 이력 → `/data/history`
- 마지막 업데이트 시간 표시

#### 5. 데이터 입력 하위 화면

| 경로 | 화면 | 입력 항목 |
|---|---|---|
| `/data/sales-input` | 매출 입력 | 월 선택 (6개월), 총 매출 (원), 카드 비율 슬라이더 |
| `/data/expense-input` | 지출 입력 | 월 선택, 총 지출 (원), 과세 매입 비율 (대부분/반반/거의없음) |
| `/data/deemed-purchase` | 의제매입 입력 | 월 선택, 프리셋 금액 선택, VAT 절감 효과 표시 |
| `/data/history` | 과거 이력 | 직전 부가세 납부액, 기장 여부, 부양가족, 노란우산공제 |

#### 6. 세금 상세 (`/tax-detail/:type`)
- 예상 납부세액 범위 바
- 구성요소 항목별 분해
  - 부가세: 매출세액, 매입세액, 의제매입세액공제, 신카발행세액공제
  - 종소세: 총수입, 필요경비, 소득, 인적공제, 노란우산공제, 과세표준, 세율, 지방소득세
- 계산 과정 펼치기 (ExpansionTile)
- 정확도 부족 시 데이터 입력 유도 카드

#### 7. 시뮬레이터 (`/simulator`)
- 현재 예상 부가세 표시
- 월 매출 변동 슬라이더 (-500만 ~ +500만)
- 월 지출 변동 슬라이더 (-300만 ~ +300만)
- 변경된 부가세·종소세 예상 + 변동폭 표시

#### 8. 설정 (`/settings`)
- 사업장 정보 확인/수정
- 부양가족 정보 확인/수정
- 알림 설정 (세금 시즌, 월별 입력)
- 앱 버전 정보

---

## 데이터 모델

### Business
```
businessType   String   'restaurant' | 'cafe' | 'other'
taxType        String   'general' | 'simplified' | 'unknown'
vatInclusive   bool     매출에 부가세 포함 여부 (기본: true)
```

### MonthlySales
```
yearMonth          DateTime   YYYY-MM-01 형식
totalSales         int        총 매출 (원)
cardSales          int?       카드 매출
cashReceiptSales   int?       현금영수증 매출
otherCashSales     int?       기타 현금 매출
─────────────
cardRatio          double     (getter) 카드 매출 비율, 기본 0.75
```

### MonthlyExpenses
```
yearMonth        DateTime   YYYY-MM-01 형식
totalExpenses    int        총 지출 (원)
taxableExpenses  int?       과세 매입액
```

### DeemedPurchase
```
yearMonth   DateTime   YYYY-MM-01 형식
amount      int        면세 식재료 매입액 (원)
```

### UserProfile
```
hasBookkeeping         bool    기장 신고 여부
dependentsSelf         bool    본인 (기본 true)
hasSpouse              bool    배우자
childrenCount          int     자녀 수
supportsParents        bool    부모님 부양
yellowUmbrella         bool    노란우산공제 가입 여부
yellowUmbrellaMonthly  int?    노란우산 월 납입액 (원)
previousVatAmount      int?    직전 부가세 납부액 (원)
─────────────
personalDeduction      int     (getter) 인적공제 총액 = 인원수 × 150만원
yellowUmbrellaAnnual   int     (getter) 노란우산공제 연간 = 월납입액 × 12
```

### TaxPrediction (계산 결과, 저장하지 않음)
```
taxType         String   'vat' | 'income_tax'
period          String   '2025년 1기', '2025년' 등
predictedMin    int      예상 최솟값 (원)
predictedMax    int      예상 최댓값 (원)
accuracyScore   int      정확도 (0~100)
actualAmount    int?     실제 납부액 (추후 비교용)
─────────────
midPoint        int      (getter) 범위 중간값
range           int      (getter) 범위 폭
```

---

## 세금 계산 로직 (`TaxCalculator`)

### 부가세 (일반과세자)

```
납부세액 = 매출세액 - 매입세액 - 의제매입세액공제 - 신카발행세액공제

① 매출세액 = 총매출 ÷ 11  (VAT 포함 기준)
② 매입세액 = 과세 매입 ÷ 11
③ 의제매입세액공제 = 면세 식재료 × 한도율 × 9/109
   - 한도율: 연매출 2억 이하 65%, 4억 이하 60%, 초과 50%
④ 신카발행세액공제 = (카드 + 현금영수증) × 1.3%, 반기 최대 500만원
```

### 종합소득세

```
기장 신고:
  과세소득 = 연 매출(VAT 제외) - 실제 경비

추계 신고:
  과세소득 = 연 매출(VAT 제외) × (1 - 단순경비율)
  - 음식점: 89.7%
  - 카페: 87.8%

과세표준 = 과세소득 - 인적공제 - 노란우산공제

세율표 (8단계 누진):
  1,400만 이하        6%
  5,000만 이하       15% - 126만
  8,800만 이하       24% - 576만
  1.5억 이하         35% - 1,544만
  3억 이하           38% - 1,994만
  5억 이하           40% - 2,594만
  10억 이하          42% - 3,594만
  10억 초과          45% - 6,594만

총 세금 = 소득세 + 지방소득세(소득세의 10%)
```

### 정확도 점수 (0~100)

```
매출 데이터 채움률    40%   해당 반기 중 입력된 월 수 / 총 월 수
지출 데이터 유무      25%   있으면 25, 없으면 0
의제매입 유무         20%   있으면 20, 없으면 0
데이터 최신성         15%   7일 이내 15, 30일 이내 10, 90일 이내 5, 초과 0
```

### 예측 범위 마진율

```
정확도에 따라 중간값(midPoint) 기준 ± 마진:
  80점 이상   ±10%
  60점 이상   ±20%
  40점 이상   ±30%
  20점 이상   ±45%
  20점 미만   ±60%
```

### 세금 날씨

```
매출 대비 세금 비율:
  3.5% 이하   sunny  (맑음)
  5.0% 이하   cloudy (흐림)
  5.0% 초과   stormy (주의)
```

---

## 유틸리티 (`Formatters`)

| 메서드 | 설명 | 예시 |
|---|---|---|
| `toManWon(int)` | 원 → 만원 | `2400000` → `"240만"` |
| `toManWonWithUnit(int)` | 원 → 만원 + 원 | `2400000` → `"240만 원"` |
| `formatWon(int)` | 원 → 콤마 포맷 | `24000000` → `"24,000,000"` |
| `formatMonth(DateTime)` | 월 포맷 | → `"2025.01"` |
| `formatDday(DateTime)` | D-day | → `"D-30"`, `"D-day"`, `"D+5"` |
| `getVatPeriod(DateTime)` | 부가세 기수 | → `"2025년 1기"` |
| `getIncomeTaxPeriod(DateTime)` | 종소세 기간 | → `"2025년"` |
| `getNextVatDeadline()` | 다음 부가세 납부일 | 1/25 또는 7/25 |
| `getNextIncomeTaxDeadline()` | 다음 종소세 납부일 | 5/31 |

---

## 공통 위젯

| 위젯 | 역할 | 사용처 |
|---|---|---|
| `NotionCard` | Notion 스타일 카드 컨테이너 | 거의 모든 화면 |
| `TaxCard` | 세금 예측 요약 카드 (범위 + D-day) | 레이더 |
| `RangeBar` | min~max 범위 시각화 바 | 레이더, 상세, 첫 결과 |
| `AccuracyGauge` | 정확도 4항목 게이지 (매출/지출/의제/최신) | 레이더 |
| `WeatherIcon` | 세금 날씨 아이콘 (sunny/cloudy/stormy) | 첫 결과 |
| `ChipSelector` | 선택형 칩 그룹 | 사업장 정보, 지출, 이력 |
| `PresetAmountPicker` | 프리셋 금액 선택기 | 첫 매출, 의제매입 |
| `SeasonBanner` | 세금 시즌 알림 배너 (D-30 이내) | 레이더 |
| `TaxCalendarCard` | 세금 납부 일정 캘린더 | 레이더 |

---

## 테마

### 색상 (`AppColors`)

| 카테고리 | 색상 | Hex |
|---|---|---|
| primary | 파랑 | `#2563EB` |
| success | 초록 | `#16A34A` |
| warning | 노랑 | `#EAB308` |
| danger | 빨강 | `#DC2626` |
| background | Notion 배경 | `#F7F6F3` |
| surface | 흰색 | `#FFFFFF` |
| textPrimary | 진한 남색 | `#1E293B` |
| textSecondary | 회색 | `#64748B` |

### 타이포그래피 (`AppTypography`)

Google Fonts의 **Noto Sans** 기반.

| 스타일 | 크기 | 무게 | 용도 |
|---|---|---|---|
| displayLarge | 32 | Bold | 스플래시 제목 |
| headlineMedium | 20 | SemiBold | 화면 타이틀 |
| titleMedium | 16 | SemiBold | 섹션 제목 |
| bodyMedium | 14 | Regular | 본문 |
| amountLarge | 28 | Bold | 금액 강조 |
| amountSmall | 16 | SemiBold | 금액 일반 |
| hint | 12 | Regular | 힌트 텍스트 (회색) |

---

## 라우팅 (`AppRouter`)

| 경로 | 화면 | 비고 |
|---|---|---|
| `/splash` | SplashScreen | 초기 진입점 |
| `/onboarding/value` | ValuePropositionScreen | 온보딩 1단계 |
| `/onboarding/business-info` | BusinessInfoScreen | 온보딩 2단계 |
| `/onboarding/first-sales` | FirstSalesScreen | 온보딩 3단계 |
| `/onboarding/first-result` | FirstResultScreen | 온보딩 4단계 (결과) |
| `/radar` | RadarScreen | ShellRoute (하단 탭) |
| `/data` | DataInputScreen | ShellRoute (하단 탭) |
| `/settings` | SettingsScreen | ShellRoute (하단 탭) |
| `/tax-detail/:type` | TaxDetailScreen | vat 또는 income_tax |
| `/simulator` | SimulatorScreen | 세금 시뮬레이터 |
| `/data/sales-input` | SalesInputScreen | 매출 입력 |
| `/data/expense-input` | ExpenseInputScreen | 지출 입력 |
| `/data/deemed-purchase` | DeemedPurchaseScreen | 의제매입 입력 |
| `/data/history` | HistoryInputScreen | 과거 이력 입력 |

---

## 프로젝트 구조

```
lib/
├── main.dart                              # 앱 진입점 (Hive 초기화 + Provider 설정)
├── app.dart                               # MaterialApp.router 설정
├── router/
│   └── app_router.dart                    # go_router 경로 정의
├── models/
│   ├── business.dart                      # 사업장 정보 모델
│   ├── monthly_sales.dart                 # 월별 매출 모델
│   ├── monthly_expenses.dart              # 월별 지출 모델
│   ├── deemed_purchase.dart               # 의제매입 모델
│   ├── tax_prediction.dart                # 세금 예측 결과 모델
│   └── user_profile.dart                  # 사용자 프로필 모델
├── providers/
│   └── business_provider.dart             # 핵심 상태 관리 + Hive 영속성
├── utils/
│   ├── tax_calculator.dart                # 부가세·종소세 계산 엔진
│   └── formatters.dart                    # 숫자·날짜·D-day 포맷
├── screens/
│   ├── splash/splash_screen.dart          # 스플래시 (2초 → 분기)
│   ├── onboarding/
│   │   ├── value_proposition_screen.dart  # 가치 제안
│   │   ├── business_info_screen.dart      # 사업장 정보 입력
│   │   ├── first_sales_screen.dart        # 첫 매출 입력
│   │   └── first_result_screen.dart       # 첫 결과 확인
│   ├── main/main_shell.dart               # 하단 탭 네비게이션 쉘
│   ├── radar/radar_screen.dart            # 레이더 대시보드
│   ├── data_input/
│   │   ├── data_input_screen.dart         # 자료함 허브
│   │   ├── sales_input_screen.dart        # 매출 입력
│   │   ├── expense_input_screen.dart      # 지출 입력
│   │   ├── deemed_purchase_screen.dart    # 의제매입 입력
│   │   └── history_input_screen.dart      # 과거 이력 입력
│   ├── tax_detail/tax_detail_screen.dart  # 세금 상세 (부가세/종소세)
│   ├── simulator/simulator_screen.dart    # 세금 시뮬레이터
│   └── settings/settings_screen.dart      # 설정
├── widgets/
│   ├── notion_card.dart                   # Notion 스타일 카드
│   ├── tax_card.dart                      # 세금 예측 카드
│   ├── range_bar.dart                     # 범위 시각화 바
│   ├── accuracy_gauge.dart                # 정확도 게이지
│   ├── weather_icon.dart                  # 세금 날씨 아이콘
│   ├── chip_selector.dart                 # 선택형 칩 그룹
│   ├── preset_amount_picker.dart          # 프리셋 금액 선택기
│   ├── season_banner.dart                 # 세금 시즌 배너
│   └── tax_calendar_card.dart             # 세금 캘린더
└── theme/
    ├── app_colors.dart                    # 색상 상수
    ├── app_typography.dart                # 타이포그래피 (Noto Sans)
    └── app_theme.dart                     # ThemeData 조합
```

---

## 시작하기

```bash
# 의존성 설치
flutter pub get

# 실행
flutter run

# 정적 분석
flutter analyze
```

## 지원 플랫폼

- iOS
- Android
- Web
- macOS
- Linux
- Windows
