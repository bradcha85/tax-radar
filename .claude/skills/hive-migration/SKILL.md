---
name: hive-migration
description: Hive 데이터 마이그레이션 가이드. Use this skill when the user asks to "모델 변경", "필드 추가", "스키마 변경", "마이그레이션", "migration", "add field", "change model", "데이터 호환", or any task involving modifying data models that are persisted in Hive. Ensures safe migration without data loss.
---

# Hive 마이그레이션 가이드

Tax Radar 프로젝트의 Hive 데이터 영속화 구조와 안전한 마이그레이션 패턴.

## 현재 영속화 구조

### Hive Box

```dart
// 단일 박스 사용
final box = await Hive.openBox('taxRadar');
```

### 저장 키 목록

| 키 | 타입 | 모델 | 설명 |
|---|---|---|---|
| `business` | `Map` | `Business` | 업종, 과세유형, VAT포함 여부 |
| `profile` | `Map` | `UserProfile` | 인적공제, 장부기장, 노란우산 |
| `salesList` | `List<Map>` | `List<MonthlySales>` | 월별 매출 데이터 |
| `expensesList` | `List<Map>` | `List<MonthlyExpenses>` | 월별 경비 데이터 |
| `deemedPurchases` | `List<Map>` | `List<DeemedPurchase>` | 의제매입 데이터 |
| `precisionTaxDraft` | `Map` | `PrecisionTaxDraft` | 정밀 세금계산 임시저장 |
| `favoriteGlossaryIds` | `List<String>` | `Set<String>` | 즐겨찾기 용어 ID |
| `recentGlossaryIds` | `List<String>` | `List<String>` | 최근 조회 용어 ID |
| `onboardingComplete` | `bool` | — | 온보딩 완료 여부 |
| `lastUpdate` | `String` (ISO 8601) | `DateTime` | 마지막 데이터 수정일 |
| `vatExtrapolationEnabled` | `bool` | — | 외삽 활성화 여부 |
| `vatPrepaymentPeriodKey` | `String` | — | 예정고지 적용 과세기간 |
| `vatPrepaymentStatus` | `String` | `VatPrepaymentStatus` | 예정고지 상태 |
| `vatPrepaymentAmount` | `int` | — | 예정고지 금액 |
| `glossaryHelpModeEnabled` | `bool` | — | 용어 도움말 모드 |

### 직렬화 패턴

모든 모델은 `toJson()` / `fromJson()` 패턴을 따른다:

```dart
class MyModel {
  final int value;
  final String name;

  MyModel({required this.value, required this.name});

  // 저장
  Map<String, dynamic> toJson() => {
    'value': value,
    'name': name,
  };

  // 복원 (default fallback 필수)
  factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
    value: json['value'] as int? ?? 0,        // ← default 필수
    name: json['name'] as String? ?? '',       // ← default 필수
  );
}
```

### Provider 저장/로드 흐름

```dart
// 저장 (_saveToStorage) — 모든 notifyListeners() 시 자동 호출
Future<void> _saveToStorage() async {
  final box = Hive.box('taxRadar');
  await box.put('business', _business.toJson());
  await box.put('salesList', _salesList.map((s) => s.toJson()).toList());
  // ... 모든 키에 대해 동일
}

// 로드 (_loadFromStorage) — init() 시 1회 호출
Future<void> _loadFromStorage() async {
  final box = Hive.box('taxRadar');
  final businessJson = box.get('business');
  if (businessJson != null) {
    _business = Business.fromJson(Map<String, dynamic>.from(businessJson));
  }
  // ... 모든 키에 대해 동일
}
```

---

## 마이그레이션 패턴

### 패턴 1: 필드 추가 (가장 흔한 케이스)

기존 모델에 새 필드를 추가할 때. **가장 안전한 패턴.**

#### 절차

```
1. 모델에 새 필드 추가 (nullable 또는 default 값 필수)
2. toJson()에 새 필드 추가
3. fromJson()에 새 필드 추가 (default fallback 포함)
4. Provider의 _saveToStorage()는 변경 불필요 (toJson이 자동 포함)
5. Provider의 _loadFromStorage()는 변경 불필요 (fromJson이 자동 처리)
```

#### 예시: MonthlySales에 `onlineSales` 필드 추가

```dart
class MonthlySales {
  final DateTime yearMonth;
  final int totalSales;
  final int? cardSales;
  final int? cashReceiptSales;
  final int? otherCashSales;
  final int? onlineSales;           // ← 새 필드

  MonthlySales({
    required this.yearMonth,
    required this.totalSales,
    this.cardSales,
    this.cashReceiptSales,
    this.otherCashSales,
    this.onlineSales,                // ← nullable이면 기본값 불필요
  });

  Map<String, dynamic> toJson() => {
    'yearMonth': yearMonth.toIso8601String(),
    'totalSales': totalSales,
    'cardSales': cardSales,
    'cashReceiptSales': cashReceiptSales,
    'otherCashSales': otherCashSales,
    'onlineSales': onlineSales,      // ← toJson에 추가
  };

  factory MonthlySales.fromJson(Map<String, dynamic> json) => MonthlySales(
    yearMonth: DateTime.parse(json['yearMonth'] as String),
    totalSales: json['totalSales'] as int? ?? 0,
    cardSales: json['cardSales'] as int?,
    cashReceiptSales: json['cashReceiptSales'] as int?,
    otherCashSales: json['otherCashSales'] as int?,
    onlineSales: json['onlineSales'] as int?,  // ← 없으면 null (안전)
  );
}
```

> **핵심:** `fromJson()`에서 새 필드가 없는 기존 데이터를 읽으면 `null` 또는 기본값이 반환된다. 별도 마이그레이션 코드가 필요 없다.

---

### 패턴 2: 필드 타입 변경

기존 필드의 타입을 변경할 때. **주의 필요.**

#### 절차

```
1. fromJson()에서 구/신 타입 모두 처리하는 파싱 로직 작성
2. toJson()은 새 타입으로만 저장
3. 앱 실행 시 구 데이터 → 신 타입으로 자동 변환 (다음 저장 시 새 포맷 적용)
```

#### 예시: `amount`를 `int` → `int` (단위 변환: 만원 → 원)

```dart
factory MyModel.fromJson(Map<String, dynamic> json) {
  // 구 데이터: 만원 단위로 저장된 경우 (version 필드로 판별)
  final version = json['_version'] as int? ?? 1;
  int amount = json['amount'] as int? ?? 0;
  if (version < 2) {
    amount = amount * 10000;  // 만원 → 원 변환
  }

  return MyModel(amount: amount);
}

Map<String, dynamic> toJson() => {
  'amount': amount,
  '_version': 2,  // 버전 태그
};
```

---

### 패턴 3: 필드 이름 변경 (rename)

#### 절차

```
1. fromJson()에서 구 이름과 신 이름 모두 체크
2. toJson()은 새 이름으로만 저장
3. 구 이름 데이터는 다음 저장 시 자동으로 새 이름으로 전환
```

#### 예시: `taxAmount` → `estimatedTax`

```dart
factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
  estimatedTax: json['estimatedTax'] as int?
      ?? json['taxAmount'] as int?    // ← fallback: 구 필드명
      ?? 0,
);

Map<String, dynamic> toJson() => {
  'estimatedTax': estimatedTax,       // ← 새 이름으로만 저장
};
```

---

### 패턴 4: 필드 삭제

#### 절차

```
1. 모델에서 필드 제거
2. toJson()에서 해당 키 제거
3. fromJson()에서 해당 키 무시 (파싱하지 않으면 됨)
4. Hive에 남아있는 구 데이터는 무시됨 (문제 없음)
```

> Hive는 스키마가 없으므로 사용하지 않는 키가 남아있어도 에러가 발생하지 않는다.

---

### 패턴 5: 새 Hive 키 추가

Provider에 새로운 최상위 데이터를 추가할 때.

#### 절차

```
1. Provider에 새 상태 변수 추가 (default 값 포함)
2. _saveToStorage()에 box.put() 추가
3. _loadFromStorage()에 box.get() 추가 (null 처리 필수)
4. notifyListeners() 호출 지점 확인
```

#### 예시

```dart
// BusinessProvider
String _newSetting = 'default';  // ← default 필수

Future<void> _saveToStorage() async {
  final box = Hive.box('taxRadar');
  // ... 기존 저장 로직
  await box.put('newSetting', _newSetting);  // ← 추가
}

Future<void> _loadFromStorage() async {
  final box = Hive.box('taxRadar');
  // ... 기존 로드 로직
  _newSetting = box.get('newSetting', defaultValue: 'default') as String;  // ← 추가
}
```

---

### 패턴 6: 리스트 아이템 구조 변경

`salesList`, `expensesList` 등 리스트 내 아이템 모델이 변경될 때.

#### 절차

```
1. 아이템 모델의 fromJson()에서 구/신 포맷 모두 처리
2. _loadFromStorage()의 리스트 파싱 로직은 변경 불필요
3. 앱 실행 → 로드 → 아이템별 fromJson 자동 변환 → 저장 시 새 포맷
```

#### 핵심 원칙

```dart
// Provider 로드 패턴 (변경 불필요)
final salesJson = box.get('salesList');
if (salesJson != null) {
  _salesList = (salesJson as List)
      .map((e) => MonthlySales.fromJson(Map<String, dynamic>.from(e)))
      .toList();
  // ↑ fromJson()이 구/신 포맷을 모두 처리하므로 여기는 수정 불필요
}
```

---

## 마이그레이션 체크리스트

모델 변경 작업 시 아래 체크리스트를 순서대로 수행한다:

```
□ 1. 변경 대상 모델의 현재 toJson()/fromJson() 읽기
□ 2. 변경 유형 판별 (필드 추가/타입변경/이름변경/삭제)
□ 3. fromJson()에 하위호환 fallback 추가
□ 4. toJson()에 새 포맷 반영
□ 5. Provider _saveToStorage() 수정 필요 여부 확인
□ 6. Provider _loadFromStorage() 수정 필요 여부 확인
□ 7. 기존 데이터로 fromJson() 테스트 작성
□ 8. 새 데이터로 toJson() → fromJson() 왕복 테스트 작성
□ 9. TaxCalculator/PrecisionTaxEngine에서 해당 필드 사용처 확인
□ 10. 관련 Screen UI에서 해당 필드 표시/입력 확인
```

---

## 위험 요소와 주의사항

### 절대 하지 말 것

| 금지 사항 | 이유 |
|---|---|
| Hive box 이름 변경 (`'taxRadar'`) | 기존 데이터 전체 유실 |
| 키 이름 변경 (예: `salesList` → `monthlySales`) | 기존 데이터 로드 실패 |
| `fromJson()`에서 default fallback 누락 | 기존 사용자 앱 크래시 |
| `as int` 등 null 불가 캐스팅 | 기존 데이터에 해당 키 없으면 크래시 |
| `List.from()` 대신 `as List` 직접 캐스팅 | Hive 반환 타입이 `List<dynamic>`이므로 타입 에러 |

### 안전한 캐스팅 패턴

```dart
// BAD — 크래시 위험
final value = json['amount'] as int;

// GOOD — null-safe
final value = json['amount'] as int? ?? 0;

// BAD — 타입 에러 위험
final list = json['items'] as List<Map<String, dynamic>>;

// GOOD — 안전한 변환
final list = (json['items'] as List?)
    ?.map((e) => Map<String, dynamic>.from(e as Map))
    .toList() ?? [];
```

### DateTime 직렬화

```dart
// 저장
'yearMonth': yearMonth.toIso8601String(),

// 복원
yearMonth: DateTime.parse(json['yearMonth'] as String),

// 안전한 복원 (파싱 실패 대비)
yearMonth: DateTime.tryParse(json['yearMonth'] as String? ?? '') ?? DateTime.now(),
```

---

## 테스트 템플릿

모델 변경 시 반드시 추가할 테스트:

```dart
group('MyModel 마이그레이션', () {
  test('v1 데이터 (구 포맷) → fromJson 정상 로드', () {
    final oldJson = {
      'amount': 100,
      // 새 필드 없음
    };
    final model = MyModel.fromJson(oldJson);
    expect(model.amount, 100);
    expect(model.newField, isNull);  // 또는 default 값
  });

  test('v2 데이터 (신 포맷) → fromJson 정상 로드', () {
    final newJson = {
      'amount': 100,
      'newField': 'value',
    };
    final model = MyModel.fromJson(newJson);
    expect(model.amount, 100);
    expect(model.newField, 'value');
  });

  test('toJson → fromJson 왕복 테스트', () {
    final original = MyModel(amount: 100, newField: 'value');
    final json = original.toJson();
    final restored = MyModel.fromJson(json);
    expect(restored.amount, original.amount);
    expect(restored.newField, original.newField);
  });
});
```
