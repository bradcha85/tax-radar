# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tax Radar (세금레이더) — 음식점/카페 자영업자를 위한 부가세·종소세 예측 Flutter 앱. 서버 없이 100% 로컬에서 동작하며, Hive로 데이터를 기기에만 저장한다.

## Commands

```bash
# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis (linting)
flutter analyze

# Format code
dart format lib/

# Get dependencies
flutter pub get
```

## Architecture

**Layered architecture with Provider state management:**

```
Screens (UI) → BusinessProvider (state + Hive persistence) → TaxCalculator (pure computation)
```

- **State management:** Single `BusinessProvider` (ChangeNotifier) manages all app state and persists to Hive automatically on every change.
- **Database:** Hive local NoSQL — single box `'taxRadar'` with keys: `business`, `profile`, `salesList`, `expensesList`, `deemedPurchases`, `onboardingComplete`, `lastUpdate`.
- **Routing:** `go_router` with a `ShellRoute` for bottom navigation (`/radar`, `/data`, `/settings`) and standalone routes for onboarding, detail, and simulator screens.
- **No network calls.** All tax calculations are local. No backend, no API.

### Key Source Directories

- `lib/models/` — Data models with `toJson`/`fromJson` (Business, MonthlySales, MonthlyExpenses, DeemedPurchase, UserProfile, TaxPrediction)
- `lib/providers/business_provider.dart` — Central state: holds all data, computes predictions, manages Hive persistence
- `lib/utils/tax_calculator.dart` — Pure tax computation (VAT and income tax formulas for Korean tax law)
- `lib/utils/formatters.dart` — Korean currency formatting (`toManWon`), date formatting, tax period/deadline helpers
- `lib/screens/` — Organized by feature: `splash/`, `onboarding/`, `main/`, `radar/`, `data_input/`, `tax_detail/`, `simulator/`, `settings/`
- `lib/widgets/` — Reusable components (NotionCard, TaxCard, AccuracyGauge, WeatherIcon, etc.)
- `lib/theme/` — AppColors, AppTypography, AppTheme (Notion-inspired design with Noto Sans)
- `lib/router/app_router.dart` — GoRouter configuration with all routes

### Tax Calculation Logic

**VAT (반기별):** `매출세액 - 매입세액 - 의제매입세액공제 - 신용카드발행세액공제`
- 의제매입세액 한도율: 매출 2억↓ 65%, 4억↓ 60%, 초과 50%
- 신용카드공제: (카드+현금영수증) × 1.3%, 반기 최대 500만

**종소세 (연간):** 기장 vs 단순경비율 방식
- 단순경비율: 음식점 89.7%, 카페 87.8%
- 8단계 누진세율 (6%~45%) + 지방소득세 10%

**정확도 점수 (0-100):** 매출입력 40 + 경비 25 + 의제매입 20 + 최신성 15

### Navigation Flow

1. Splash → onboarding check
2. Onboarding: value proposition → business info → first sales → first result
3. Main shell (bottom nav): Radar dashboard | Data input | Settings
4. Detail screens: `/tax-detail/:type` (vat/income_tax), `/simulator`

## Conventions

- **Language:** UI text and comments are in Korean
- **Currency:** All monetary values stored as `int` (원 단위)
- **Date convention:** `yearMonth` fields use first-of-month DateTime (YYYY-MM-01), serialized as ISO 8601
- **Theme:** Notion-inspired — background `#F7F6F3`, primary `#2563EB`, card radius 8px
- **Dependencies:** Provider for state, go_router for navigation, Hive for persistence, intl for formatting, google_fonts (Noto Sans)
