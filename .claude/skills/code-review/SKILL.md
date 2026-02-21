---
name: code-review
description: 코드 리뷰 및 리팩토링 가이드. Use this skill when the user asks to "리뷰", "리팩토링", "코드 정리", "code review", "refactor", "split file", "파일 분리", or any task involving reviewing, restructuring, or improving existing code quality. Enforces project conventions and identifies improvement opportunities.
---

# 코드 리뷰 & 리팩토링 가이드

Tax Radar 프로젝트의 코드 품질 기준과 리팩토링 패턴.

## 프로젝트 컨벤션

### 파일 구조 규칙

```
lib/
├── models/          → 데이터 클래스 (toJson/fromJson, 불변 우선)
├── providers/       → ChangeNotifier (상태 + Hive 영속화)
├── utils/           → 순수 함수 유틸리티 (side-effect 없음)
├── screens/         → 화면별 디렉토리 (screen + 전용 위젯)
├── widgets/         → 2개 이상 화면에서 공유하는 위젯
├── theme/           → 디자인 토큰 (색상, 타이포, 테마)
├── router/          → GoRouter 설정
└── data/            → 정적 데이터 (용어사전 등)
```

### 네이밍 규칙

| 대상 | 규칙 | 예시 |
|---|---|---|
| 파일명 | snake_case | `tax_calculator.dart` |
| 클래스 | PascalCase | `TaxCalculator`, `VatBreakdown` |
| 변수/함수 | camelCase | `taxBase`, `calculateVat()` |
| private | `_` prefix | `_applyTaxBracket()`, `_business` |
| 상수 | camelCase | `specialEnd` (Dart convention) |
| 열거형 값 | camelCase | `BusinessType.restaurant` |

### 코드 스타일

- **언어:** UI 텍스트, 주석 모두 한국어
- **통화:** 모든 금액은 `int` (원 단위)
- **날짜:** `yearMonth`는 매월 1일 DateTime (`YYYY-MM-01`), ISO 8601 직렬화
- **trailing comma:** 컬렉션, 위젯 트리에 항상 사용
- **const:** 가능한 모든 곳에 `const` 사용
- **import 순서:** dart → package → 프로젝트 상대경로

---

## 리뷰 체크리스트

### 1. 아키텍처 준수

```
□ Screen이 직접 Hive에 접근하지 않는가? (Provider를 통해서만)
□ TaxCalculator/PrecisionTaxEngine에 side-effect가 없는가?
□ 새 상태가 필요하면 BusinessProvider에 추가했는가?
□ Provider 변경 시 _saveToStorage()가 호출되는가?
```

### 2. 모델 규칙

```
□ toJson() / fromJson() 쌍이 구현되어 있는가?
□ fromJson()에 default fallback이 있는가? (기존 데이터 호환)
□ 금액 필드는 int 타입인가?
□ yearMonth 필드는 DateTime (매월 1일)인가?
□ copyWith() 메서드가 필요하다면 구현되어 있는가?
```

### 3. 세금 계산 로직

```
□ 순수 함수인가? (static, no side-effect)
□ 날짜 의존 상수에 asOf 파라미터가 있는가?
□ 일몰 조항의 DateTime 비교가 정확한가?
□ _Fraction 기반 반올림을 사용하는가? (부동소수점 회피)
□ tax_calculator_test.dart에 테스트가 추가되었는가?
```

### 4. UI/위젯 규칙

```
□ AppColors, AppTypography 상수를 사용하는가? (하드코딩 금지)
□ 금액 표시에 Formatters.toManWon() 또는 formatWon()을 사용하는가?
□ SafeArea로 감싸져 있는가?
□ 스크롤 가능한 콘텐츠에 SingleChildScrollView 또는 ListView를 사용하는가?
□ NotionCard 기반 카드 레이아웃을 따르는가?
```

### 5. 성능

```
□ Provider에서 불필요한 notifyListeners() 호출이 없는가?
□ 리스트 연산에서 불필요한 toList() 변환이 없는가?
□ build() 안에서 무거운 계산을 하지 않는가? (getter 캐싱 고려)
□ const 위젯을 최대한 활용하는가?
```

---

## 리팩토링 패턴

### 패턴 1: 대형 Screen 파일 분리

**기준:** 500줄 이상의 Screen 파일은 분리를 고려한다.

**현재 대형 파일:**

| 파일 | 줄 수 | 분리 방안 |
|---|---|---|
| `precision_tax_screen.dart` | ~1,800줄 | 스텝별 위젯 분리 |
| `tax_detail_screen.dart` | ~1,790줄 | 섹션별 위젯 분리 |
| `radar_screen.dart` | ~1,020줄 | 카드/캘린더 위젯 분리 |

**분리 전략:**

```
screens/tax_detail/
├── tax_detail_screen.dart       ← 메인 Scaffold + 전체 레이아웃
├── widgets/
│   ├── vat_breakdown_section.dart
│   ├── income_breakdown_section.dart
│   ├── glassmorphic_hero.dart
│   └── estimation_basis_card.dart
```

**규칙:**
- 분리된 위젯은 `screens/{feature}/widgets/`에 배치
- 2개 이상 screen에서 사용하면 `lib/widgets/`로 승격
- 분리된 위젯은 필요한 데이터를 파라미터로 받는다 (Provider 직접 접근 최소화)

### 패턴 2: 계산 로직 추출

**기준:** Screen이나 Provider 안에 세금 계산이 인라인되어 있으면 추출한다.

```dart
// BAD: Screen 안에서 직접 계산
final tax = revenue * 0.06;

// GOOD: TaxCalculator로 위임
final tax = TaxCalculator.calculateIncomeTax(...);
```

### 패턴 3: 매직 넘버 상수화

```dart
// BAD
if (taxBase <= 200000000) return 0.50;

// GOOD
static const _deemedLimitThreshold = 200000000;
static const _deemedLimitRateSmall = 0.50;
if (taxBase <= _deemedLimitThreshold) return _deemedLimitRateSmall;
```

**예외:** 세법에서 직접 정의한 숫자 (세율, 누진공제액 등)는 코드 내 인라인이 허용된다. 단, 주석으로 근거를 명시한다.

### 패턴 4: Provider 메서드 정리

**기준:** BusinessProvider에 getter가 20개 이상이면 Extension 또는 Mixin으로 분리를 고려한다.

```dart
// 분리 예시
mixin VatCalculationMixin on ChangeNotifier {
  // VAT 관련 getter/method
}

mixin IncomeTaxCalculationMixin on ChangeNotifier {
  // 종소세 관련 getter/method
}

class BusinessProvider extends ChangeNotifier
    with VatCalculationMixin, IncomeTaxCalculationMixin {
  // 핵심 상태만 관리
}
```

### 패턴 5: 테스트 추가 우선순위

신규 코드에 테스트를 추가할 때의 우선순위:

1. **필수:** 세금 계산 로직 (`tax_calculator_test.dart`)
2. **필수:** 모델 직렬화 (`fromJson` → `toJson` 왕복 테스트)
3. **권장:** Provider 상태 변경 (통합 테스트)
4. **선택:** 위젯 렌더링 (위젯 테스트)

---

## 리뷰 출력 포맷

코드 리뷰 결과는 다음 형식으로 출력한다:

```markdown
## 코드 리뷰 결과

### 요약
- 전체 평가: [좋음/보통/개선필요]
- 검토 파일: N개
- 발견 사항: N개 (심각 N / 주의 N / 제안 N)

### 발견 사항

#### 🔴 심각 (반드시 수정)
1. **[파일:줄번호]** 설명
   - 현재: `코드`
   - 제안: `코드`

#### 🟡 주의 (수정 권장)
1. **[파일:줄번호]** 설명

#### 🟢 제안 (선택적 개선)
1. **[파일:줄번호]** 설명
```

---

## Anti-Patterns (피해야 할 것)

| Anti-Pattern | 올바른 방식 |
|---|---|
| Screen에서 Hive 직접 접근 | Provider를 통해 접근 |
| `double`로 금액 계산 | `int` (원 단위) + `_Fraction` |
| 하드코딩 색상 `Color(0xFF...)` | `AppColors.primary` 등 상수 사용 |
| `setState` 남용 | Provider + `notifyListeners()` |
| 무한 스크롤 없이 큰 리스트 렌더링 | `ListView.builder` 사용 |
| `context.read` in `build()` | `context.watch` 또는 `Consumer` 사용 |
| 날짜 비교 시 `DateTime.now()` 직접 사용 | `asOf` 파라미터로 주입 (테스트 용이) |
