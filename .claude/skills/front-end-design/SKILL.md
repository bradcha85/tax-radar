---
name: front-end-design
description: 프론트엔드 디자인 시스템 가이드. Use this skill when the user asks to "build UI", "design screen", "화면 만들어", "UI 구현", "디자인 적용", "스타일 수정", "위젯 만들어", or any task involving creating, modifying, or reviewing Flutter UI components. Ensures all UI code follows the project's minimal SaaS design system with teal/gold color palette.
---

# Front-End Design System

Tax Radar 프로젝트의 프론트엔드 디자인 가이드. 미니멀한 SaaS 스타일의 모바일 앱 디자인 시스템.

## Design Concept

**미니멀 SaaS 핀테크 모바일 앱.** 깔끔하고 신뢰감 있는 인터페이스. 숫자와 데이터가 시각적 주인공. 불필요한 장식 없이 정보 계층 구조로 시각적 리듬을 만든다.

### 핵심 원칙

1. **정보 우선** — 금액, 세율 등 핵심 수치가 가장 먼저 눈에 들어와야 한다
2. **여백의 미** — 넉넉한 패딩과 간격으로 콘텐츠가 숨 쉴 공간을 확보
3. **일관된 카드 시스템** — 모든 정보 블록은 카드 단위로 그룹핑
4. **컬러 절제** — 핵심 액션과 금액에만 컬러를 사용하고 나머지는 뉴트럴 톤

## Color Palette

### Primary Colors

| Role | Hex | Flutter Constant | 용도 |
|---|---|---|---|
| Primary | `#087F8C` | `Color(0xFF087F8C)` | 버튼, 네비게이션, 링크, 활성 상태, 프로그레스바 |
| Primary Dark | `#095256` | `Color(0xFF095256)` | 앱바 텍스트 강조, 깊은 배경 |
| Primary Light | `#E6F4F3` | `Color(0xFFE6F4F3)` | 선택 상태 배경, 칩, 배지, 태그 |

### Accent Colors

| Role | Hex | Flutter Constant | 용도 |
|---|---|---|---|
| Accent | `#BB9F06` | `Color(0xFFBB9F06)` | 금액 표시, CTA 강조, 핵심 수치 |
| Accent Light | `#FBF7E4` | `Color(0xFFFBF7E4)` | 강조 카드 배경, 절세 팁 배경 |

### Neutral Colors

| Role | Hex | Flutter Constant | 용도 |
|---|---|---|---|
| Background | `#F7FAF9` | `Color(0xFFF7FAF9)` | 앱 전체 배경 (미묘한 틸 틴트) |
| Surface | `#FFFFFF` | `Color(0xFFFFFFFF)` | 카드, 시트, 입력 필드, 바텀내비 |
| Border | `#D6E5E3` | `Color(0xFFD6E5E3)` | 카드 테두리, 구분선, 입력 필드 보더 |

### Text Colors

| Role | Hex | Flutter Constant | 용도 |
|---|---|---|---|
| Text Primary | `#0A2E2F` | `Color(0xFF0A2E2F)` | 제목, 본문, 금액 |
| Text Secondary | `#5F7A7C` | `Color(0xFF5F7A7C)` | 설명, 보조 텍스트, 라벨 |
| Text Hint | `#9CB3B5` | `Color(0xFF9CB3B5)` | 플레이스홀더, 비활성 탭 |
| Text On Primary | `#FFFFFF` | `Color(0xFFFFFFFF)` | Primary 배경 위 텍스트 |

### Status Colors

| Role | Hex | Flutter Constant | 용도 |
|---|---|---|---|
| Success | `#2D9F6F` | `Color(0xFF2D9F6F)` | 완료, 긍정 수치, 정확도 높음 |
| Warning | `#D97706` | `Color(0xFFD97706)` | 주의, 미완료, 정확도 보통 |
| Danger | `#DC2626` | `Color(0xFFDC2626)` | 오류, 삭제, 감소 |

## Design Tokens

```
Font: Noto Sans KR (google_fonts)
Card radius: 12px
Button radius: 12px
Input radius: 8px
Chip radius: 20px (fully rounded)
Card: white #FFFFFF, 1px border #D6E5E3, no shadow
Spacing grid: 8px base unit
Horizontal page padding: 20px
Card internal padding: 20px
Section gap: 24px
Bottom nav: 4 tabs (홈, 장부, 세무, 설정)
Language: 모든 UI 텍스트는 한국어
Icons: Material Icons, outlined style
```

## Component Specifications

### Cards

```dart
// 기본 카드
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFD6E5E3), width: 1),
  ),
)

// 강조 카드 (절세 팁 등)
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Color(0xFFFBF7E4), // accent light
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFD6E5E3), width: 1),
  ),
)
```

### Buttons

```dart
// Primary CTA 버튼
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF087F8C),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
)

// Secondary 버튼 (상세보기 등)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF0A2E2F),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
)
```

### 금액 표시

```dart
// 큰 금액 (카드 주요 수치) — accent gold
Text(
  '약 320만원',
  style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Color(0xFFBB9F06), // accent gold
  ),
)

// 보조 금액 (이번 달 현황 등)
Text(
  '4,200만',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Color(0xFF0A2E2F), // text primary
  ),
)
```

### 배지/태그

```dart
// 기간 배지 (2026년 1기)
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFFE6F4F3), // primary light
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    '2026년 1기',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF087F8C), // primary
    ),
  ),
)

// 정확도 배지
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: Color(0xFF0A2E2F).withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, size: 14, color: Color(0xFF2D9F6F)),
      SizedBox(width: 4),
      Text('정확도 72%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  ),
)
```

### 프로그레스바

```dart
// 분석 완료율 바
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: 0.72,
    backgroundColor: Color(0xFFD6E5E3),
    valueColor: AlwaysStoppedAnimation(Color(0xFF087F8C)),
    minHeight: 6,
  ),
)
```

### Bottom Navigation Bar

```dart
// 4탭: 홈, 장부, 세무, 설정
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: Color(0xFFFFFFFF),
  selectedItemColor: Color(0xFF087F8C),
  unselectedItemColor: Color(0xFF9CB3B5),
  elevation: 0,
  selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: '장부'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: '세무'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '설정'),
  ],
)
```

## Layout Patterns

### 레이더 (홈) 화면 구조

레퍼런스 이미지 기반 레이아웃 (위에서 아래 순서):

```
[20px 상단 패딩]
[앱 로고 + "세금레이더" 타이틀 ---- 알림 아이콘]  ← AppBar 영역
[기간 배지: "2026년 1기"]                          ← primary light 배경 둥근 칩
[인사말: "사장님,\n다음 부가세 예상액이에요"]        ← 큰 제목, 2줄
[24px gap]
[부가세 카드]                                       ← 메인 카드, accent gold 금액
  ├─ 상단: "부가세 ⓘ" + 정확도 배지
  ├─ 금액: "약 320만원" (accent gold, 28pt bold)
  ├─ 납부기한 + "상세보기 →" 버튼
  └─ 하단: D-day 텍스트 + 프로그레스바 + "72% 분석 완료"
[16px gap]
[종소세 카드]                                       ← 서브 카드, 심플
  ├─ "종합소득세" + 정확도 배지
  ├─ 금액: "약 480만원"
  └─ 납부일 + 화살표
[24px gap]
["이번 달 현황" 섹션 헤더 ---- "전체보기 >"]
[가로 스크롤 미니 카드들]                            ← 매출, 매입경비, 공제 예상
  ├─ 매출: 아이콘 + "4,200만" + "지난달 +12%"
  ├─ 매입 경비: 아이콘 + "1,800만" + "세금계산서 발행분"
  └─ 공제: 아이콘 + "89만" + "공제 예상"
[24px gap]
[절세 팁 카드]                                      ← accent light 배경
  ├─ 💡 "절세 팁"
  └─ 팁 본문 텍스트
[Bottom Nav: 홈(active) | 장부 | 세무 | 설정]
```

### 섹션 헤더 패턴

```dart
// "이번 달 현황" + "전체보기 >"
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('이번 달 현황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0A2E2F))),
    TextButton(
      child: Text('전체보기 >', style: TextStyle(fontSize: 14, color: Color(0xFF5F7A7C))),
    ),
  ],
)
```

### 가로 스크롤 미니 카드

```dart
// 이번 달 현황 미니 카드
SizedBox(
  height: 120,
  child: ListView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: 20),
    children: [
      _MiniCard(icon: Icons.point_of_sale, label: '매출', value: '4,200만', sub: '지난달 +12%', subColor: Color(0xFF2D9F6F)),
      SizedBox(width: 12),
      _MiniCard(icon: Icons.shopping_cart, label: '매입 경비', value: '1,800만', sub: '세금계산서 발행분'),
      // ...
    ],
  ),
)
```

## Typography Scale

| 용도 | Size | Weight | Color |
|---|---|---|---|
| 페이지 인사말/제목 | 24px | Bold (w700) | `#0A2E2F` |
| 카드 금액 (주요) | 28px | Bold (w700) | `#BB9F06` |
| 카드 금액 (보조) | 22px | Bold (w700) | `#0A2E2F` |
| 섹션 헤더 | 18px | Bold (w700) | `#0A2E2F` |
| 카드 타이틀 | 16px | SemiBold (w600) | `#0A2E2F` |
| 본문 | 14px | Regular (w400) | `#0A2E2F` |
| 보조 텍스트 | 14px | Regular (w400) | `#5F7A7C` |
| 캡션/라벨 | 12px | Medium (w500) | `#5F7A7C` |
| 힌트/플레이스홀더 | 12px | Regular (w400) | `#9CB3B5` |
| 배지 텍스트 | 13px | SemiBold (w600) | context-dependent |

## Implementation Rules

1. **AppColors 사용** — 하드코딩된 컬러 대신 반드시 `AppColors` 상수를 사용할 것. 새 컬러가 필요하면 `app_colors.dart`에 추가.

2. **카드는 Container + BoxDecoration** — `Card` 위젯 대신 `Container`에 `BoxDecoration`을 직접 적용하여 미세한 스타일 제어.

3. **elevation 0** — 모든 곳에서 그림자 제거. 깊이감은 배경색 대비와 보더로 표현.

4. **금액은 항상 강조** — 세금 금액은 accent gold(`#BB9F06`), 일반 금액은 text primary(`#0A2E2F`) bold.

5. **여백 규칙** — 페이지 좌우 패딩 20px, 카드 내부 패딩 20px, 섹션 간격 24px, 카드 간격 16px.

6. **반응형 고려** — 금액 텍스트가 길어질 수 있으므로 `FittedBox` 또는 `AutoSizeText` 고려.

7. **아이콘** — Material Icons outlined 스타일 기본. 활성 상태에서만 filled.

8. **한국어** — 모든 UI 텍스트, 주석, 에러 메시지는 한국어.

9. **기존 위젯 재활용** — `lib/widgets/`의 기존 컴포넌트(NotionCard, TaxCard 등)를 최대한 활용하고, 새 위젯이 필요할 때만 추가.

10. **상태 관리** — UI 로직은 `BusinessProvider`를 통해 접근. 화면에서 직접 계산하지 않는다.
