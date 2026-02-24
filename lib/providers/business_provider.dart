import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/business.dart';
import '../models/monthly_sales.dart';
import '../models/monthly_expenses.dart';
import '../models/deemed_purchase.dart';
import '../models/tax_prediction.dart';
import '../models/user_profile.dart';
import '../models/vat_breakdown.dart';
import '../models/income_tax_breakdown.dart';
import '../models/precision_tax.dart';
import '../models/vat_prepayment.dart';
import '../utils/tax_calculator.dart';
import '../utils/formatters.dart';

class BusinessProvider extends ChangeNotifier {
  // ============================================================
  // State
  // ============================================================

  Business _business = Business();
  Business get business => _business;

  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  final List<MonthlySales> _salesList = [];
  List<MonthlySales> get salesList => List.unmodifiable(_salesList);

  final List<MonthlyExpenses> _expensesList = [];
  List<MonthlyExpenses> get expensesList => List.unmodifiable(_expensesList);

  final List<DeemedPurchase> _deemedPurchases = [];
  List<DeemedPurchase> get deemedPurchases =>
      List.unmodifiable(_deemedPurchases);

  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  DateTime? _lastUpdate;
  DateTime? get lastUpdate => _lastUpdate;

  PrecisionTaxDraft _precisionTaxDraft = PrecisionTaxDraft.initial(
    now: DateTime.now(),
  );
  PrecisionTaxDraft get precisionTaxDraft => _precisionTaxDraft;

  final Set<String> _favoriteGlossaryIds = <String>{};
  Set<String> get favoriteGlossaryIds => Set.unmodifiable(_favoriteGlossaryIds);

  final List<String> _recentGlossaryIds = <String>[];
  List<String> get recentGlossaryIds => List.unmodifiable(_recentGlossaryIds);

  bool _vatExtrapolationEnabled = true;
  bool get vatExtrapolationEnabled => _vatExtrapolationEnabled;

  String? _vatPrepaymentPeriodKey;
  VatPrepaymentStatus _vatPrepaymentStatus = VatPrepaymentStatus.unset;
  int? _vatPrepaymentAmount;

  bool _glossaryHelpModeEnabled = false;
  bool get glossaryHelpModeEnabled => _glossaryHelpModeEnabled;

  bool _weeklyReminderEnabled = false;
  bool get weeklyReminderEnabled => _weeklyReminderEnabled;

  late Box _box;

  Future<void> init() async {
    final box = await Hive.openBox('taxRadar');
    _box = box;
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      // Business
      final businessJson = _box.get('business');
      if (businessJson != null) {
        _business = Business.fromJson(Map<String, dynamic>.from(businessJson));
      }

      // Profile
      final profileJson = _box.get('profile');
      if (profileJson != null) {
        _profile =
            UserProfile.fromJson(Map<String, dynamic>.from(profileJson));
      }

      // Sales
      final salesJsonList = _box.get('salesList');
      if (salesJsonList != null) {
        _salesList.clear();
        for (final item in salesJsonList) {
          try {
            _salesList.add(
              MonthlySales.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (e) {
            debugPrint('[TaxRadar] salesList 항목 파싱 실패: $e');
          }
        }
        _salesList.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
      }

      // Expenses
      final expensesJsonList = _box.get('expensesList');
      if (expensesJsonList != null) {
        _expensesList.clear();
        for (final item in expensesJsonList) {
          try {
            _expensesList.add(
              MonthlyExpenses.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (e) {
            debugPrint('[TaxRadar] expensesList 항목 파싱 실패: $e');
          }
        }
        _expensesList.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
      }

      // Deemed purchases
      final deemedJsonList = _box.get('deemedPurchases');
      if (deemedJsonList != null) {
        _deemedPurchases.clear();
        for (final item in deemedJsonList) {
          try {
            _deemedPurchases.add(
              DeemedPurchase.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (e) {
            debugPrint('[TaxRadar] deemedPurchases 항목 파싱 실패: $e');
          }
        }
        _deemedPurchases.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
      }

      // App state
      _onboardingComplete =
          _box.get('onboardingComplete', defaultValue: false);

      final lastUpdateStr = _box.get('lastUpdate');
      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.tryParse(lastUpdateStr);
      }

      final precisionDraftJson = _box.get('precisionTaxDraft');
      if (precisionDraftJson is Map) {
        _precisionTaxDraft = PrecisionTaxDraft.fromJson(
          Map<String, dynamic>.from(precisionDraftJson),
        );
      } else {
        _precisionTaxDraft = PrecisionTaxDraft.initial(now: DateTime.now());
      }

      final favoriteGlossaryIds = _box.get('favoriteGlossaryIds');
      _favoriteGlossaryIds.clear();
      if (favoriteGlossaryIds is List) {
        _favoriteGlossaryIds.addAll(
          favoriteGlossaryIds.whereType<String>().where(
            (item) => item.trim().isNotEmpty,
          ),
        );
      }

      final recentGlossaryIds = _box.get('recentGlossaryIds');
      _recentGlossaryIds.clear();
      if (recentGlossaryIds is List) {
        _recentGlossaryIds.addAll(
          recentGlossaryIds.whereType<String>().where(
            (item) => item.trim().isNotEmpty,
          ),
        );
      }

      _vatExtrapolationEnabled = _box.get(
        'vatExtrapolationEnabled',
        defaultValue: true,
      );

      _vatPrepaymentPeriodKey = _box.get('vatPrepaymentPeriodKey') as String?;
      final vatPrepaymentStatusRaw =
          _box.get('vatPrepaymentStatus') as String?;
      _vatPrepaymentStatus = VatPrepaymentStatus.values.firstWhere(
        (item) => item.name == vatPrepaymentStatusRaw,
        orElse: () => VatPrepaymentStatus.unset,
      );
      final vatPrepaymentAmountRaw = _box.get('vatPrepaymentAmount');
      _vatPrepaymentAmount =
          vatPrepaymentAmountRaw is int ? vatPrepaymentAmountRaw : null;

      _glossaryHelpModeEnabled = _box.get(
        'glossaryHelpModeEnabled',
        defaultValue: false,
      );

      _weeklyReminderEnabled = _box.get(
        'weeklyReminderEnabled',
        defaultValue: false,
      );
    } catch (e) {
      debugPrint('[TaxRadar] _loadFromStorage 실패, 기본값 사용: $e');
    }

    notifyListeners();
  }

  void _saveToStorage() {
    _box.put('business', _business.toJson());
    _box.put('profile', _profile.toJson());
    _box.put('salesList', _salesList.map((s) => s.toJson()).toList());
    _box.put('expensesList', _expensesList.map((e) => e.toJson()).toList());
    _box.put(
      'deemedPurchases',
      _deemedPurchases.map((d) => d.toJson()).toList(),
    );
    _box.put('onboardingComplete', _onboardingComplete);
    _box.put('precisionTaxDraft', _precisionTaxDraft.toJson());
    _box.put('favoriteGlossaryIds', _favoriteGlossaryIds.toList());
    _box.put('recentGlossaryIds', _recentGlossaryIds);
    _box.put('vatExtrapolationEnabled', _vatExtrapolationEnabled);
    _box.put('vatPrepaymentPeriodKey', _vatPrepaymentPeriodKey);
    _box.put('vatPrepaymentStatus', _vatPrepaymentStatus.name);
    _box.put('vatPrepaymentAmount', _vatPrepaymentAmount);
    _box.put('glossaryHelpModeEnabled', _glossaryHelpModeEnabled);
    _box.put('weeklyReminderEnabled', _weeklyReminderEnabled);
    if (_lastUpdate != null) {
      _box.put('lastUpdate', _lastUpdate!.toIso8601String());
    }
  }

  // ============================================================
  // Data Reset
  // ============================================================

  Future<void> resetAllData() async {
    await _box.clear();
    _business = Business();
    _profile = UserProfile();
    _salesList.clear();
    _expensesList.clear();
    _deemedPurchases.clear();
    _onboardingComplete = false;
    _lastUpdate = null;
    _precisionTaxDraft = PrecisionTaxDraft.initial(now: DateTime.now());
    _favoriteGlossaryIds.clear();
    _recentGlossaryIds.clear();
    _vatExtrapolationEnabled = true;
    _vatPrepaymentPeriodKey = null;
    _vatPrepaymentStatus = VatPrepaymentStatus.unset;
    _vatPrepaymentAmount = null;
    _glossaryHelpModeEnabled = false;
    _weeklyReminderEnabled = false;
    notifyListeners();
  }

  // ============================================================
  // Business Info
  // ============================================================

  void updateBusiness({
    String? businessType,
    String? taxType,
    bool? vatInclusive,
  }) {
    if (businessType != null) _business.businessType = businessType;
    if (taxType != null) _business.taxType = taxType;
    if (vatInclusive != null) _business.vatInclusive = vatInclusive;
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // User Profile
  // ============================================================

  void updateProfile({
    bool? hasBookkeeping,
    bool? hasSpouse,
    int? childrenCount,
    bool? supportsParents,
    bool? yellowUmbrella,
    int? yellowUmbrellaMonthly,
    int? previousVatAmount,
  }) {
    if (hasBookkeeping != null) _profile.hasBookkeeping = hasBookkeeping;
    if (hasSpouse != null) _profile.hasSpouse = hasSpouse;
    if (childrenCount != null) _profile.childrenCount = childrenCount;
    if (supportsParents != null) _profile.supportsParents = supportsParents;
    if (yellowUmbrella != null) _profile.yellowUmbrella = yellowUmbrella;
    if (yellowUmbrellaMonthly != null) {
      _profile.yellowUmbrellaMonthly = yellowUmbrellaMonthly;
    }
    if (previousVatAmount != null) {
      _profile.previousVatAmount = previousVatAmount;
    }
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // Sales
  // ============================================================

  void addSales(MonthlySales sales) {
    // 같은 월 데이터가 있으면 교체
    _salesList.removeWhere(
      (s) =>
          s.yearMonth.year == sales.yearMonth.year &&
          s.yearMonth.month == sales.yearMonth.month,
    );
    _salesList.add(sales);
    _salesList.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  MonthlySales? getSalesForMonth(DateTime yearMonth) {
    try {
      return _salesList.firstWhere(
        (s) =>
            s.yearMonth.year == yearMonth.year &&
            s.yearMonth.month == yearMonth.month,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Expenses
  // ============================================================

  void addExpenses(MonthlyExpenses expenses) {
    _expensesList.removeWhere(
      (e) =>
          e.yearMonth.year == expenses.yearMonth.year &&
          e.yearMonth.month == expenses.yearMonth.month,
    );
    _expensesList.add(expenses);
    _expensesList.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // Deemed Purchases (의제매입)
  // ============================================================

  void addDeemedPurchase(DeemedPurchase purchase) {
    _deemedPurchases.removeWhere(
      (d) =>
          d.yearMonth.year == purchase.yearMonth.year &&
          d.yearMonth.month == purchase.yearMonth.month,
    );
    _deemedPurchases.add(purchase);
    _deemedPurchases.sort((a, b) => a.yearMonth.compareTo(b.yearMonth));
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // Onboarding
  // ============================================================

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // Precision Tax + Glossary
  // ============================================================

  void updatePrecisionTaxDraft(PrecisionTaxDraft draft) {
    _precisionTaxDraft = draft;
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  void resetPrecisionTaxDraft() {
    _precisionTaxDraft = PrecisionTaxDraft.initial(now: DateTime.now());
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  int get precisionWizardCompletionPercent {
    final draft = _precisionTaxDraft;
    final hasSales = draft.businessInputMode == BusinessInputMode.annual
        ? draft.annualSales.hasValue
        : draft.monthlyBusinessInputs.any((item) => item.sales.hasValue);
    final hasExpense = draft.bookkeeping
        ? (draft.businessInputMode == BusinessInputMode.annual
              ? draft.annualExpenses.hasValue
              : draft.monthlyBusinessInputs.any(
                  (item) => item.expenses.hasValue,
                ))
        : true;
    final hasPrepaymentEvidence =
        draft.midtermPrepaymentSelection != SelectionState.unset ||
        draft.otherPrepaymentSelection != SelectionState.unset ||
        (draft.hasLaborIncome &&
            draft.laborIncome.withholdingTax.status !=
                PrecisionValueStatus.missing) ||
        (draft.hasPensionIncome &&
            draft.pensionIncome.withholdingTax.status !=
                PrecisionValueStatus.missing) ||
        (draft.hasFinancialIncome &&
            draft.financialIncome.withholdingTax.status !=
                PrecisionValueStatus.missing) ||
        (draft.hasOtherIncome &&
            draft.otherIncome.withholdingTax.status !=
                PrecisionValueStatus.missing);

    int score = 0;
    if (hasSales) score += 40;
    if (hasExpense) score += 30;
    if (hasPrepaymentEvidence) score += 30;
    return score.clamp(0, 100);
  }

  void toggleFavoriteGlossary(String termId) {
    if (_favoriteGlossaryIds.contains(termId)) {
      _favoriteGlossaryIds.remove(termId);
    } else {
      _favoriteGlossaryIds.add(termId);
    }
    notifyListeners();
    _saveToStorage();
  }

  void markRecentGlossary(String termId) {
    _recentGlossaryIds.remove(termId);
    _recentGlossaryIds.insert(0, termId);
    if (_recentGlossaryIds.length > 20) {
      _recentGlossaryIds.removeRange(20, _recentGlossaryIds.length);
    }
    notifyListeners();
    _saveToStorage();
  }

  void setVatExtrapolationEnabled(bool enabled) {
    if (_vatExtrapolationEnabled == enabled) return;
    _vatExtrapolationEnabled = enabled;
    notifyListeners();
    _saveToStorage();
  }

  void setVatPrepayment({
    required VatPrepaymentStatus status,
    int? amount,
  }) {
    final periodKey = Formatters.resolveVatPeriod(now: DateTime.now()).key;
    _vatPrepaymentPeriodKey = periodKey;
    _vatPrepaymentStatus = status;
    if (status == VatPrepaymentStatus.known) {
      _vatPrepaymentAmount = (amount ?? 0).clamp(0, 1 << 60).toInt();
    } else {
      _vatPrepaymentAmount = null;
    }
    _lastUpdate = DateTime.now();
    notifyListeners();
    _saveToStorage();
  }

  void setGlossaryHelpModeEnabled(bool enabled) {
    if (_glossaryHelpModeEnabled == enabled) return;
    _glossaryHelpModeEnabled = enabled;
    notifyListeners();
    _saveToStorage();
  }

  void setWeeklyReminderEnabled(bool enabled) {
    if (_weeklyReminderEnabled == enabled) return;
    _weeklyReminderEnabled = enabled;
    notifyListeners();
    _saveToStorage();
  }

  // ============================================================
  // Computed Values
  // ============================================================

  VatPeriod _currentVatPeriod(DateTime now) {
    return Formatters.resolveVatPeriod(now: now);
  }

  DateTime _vatCompletionEnd(VatPeriod period, DateTime now) {
    if (now.isBefore(period.start)) return period.start;
    final nowMonthStart = DateTime(now.year, now.month, 1);
    if (!nowMonthStart.isBefore(period.end)) return period.end;
    return DateTime(nowMonthStart.year, nowMonthStart.month + 1, 1);
  }

  int _vatElapsedMonths(VatPeriod period, DateTime now) {
    final completionEnd = _vatCompletionEnd(period, now);
    final months =
        (completionEnd.year - period.start.year) * 12 +
        (completionEnd.month - period.start.month);
    return months.clamp(0, period.totalMonths);
  }

  VatPeriod get vatPeriod {
    final now = DateTime.now();
    return _currentVatPeriod(now);
  }

  int get vatCardCreditUsedThisYear {
    return _getCardCreditUsedForVatPeriod(vatPeriod);
  }

  VatPrepaymentStatus get vatPrepaymentStatus {
    final currentKey = vatPeriod.key;
    if (_vatPrepaymentPeriodKey != currentKey) return VatPrepaymentStatus.unset;
    return _vatPrepaymentStatus;
  }

  int? get vatPrepaymentAmount {
    if (vatPrepaymentStatus != VatPrepaymentStatus.known) return null;
    return _vatPrepaymentAmount ?? 0;
  }

  int? get vatPrepaymentEffectiveAmount {
    switch (vatPrepaymentStatus) {
      case VatPrepaymentStatus.none:
        return 0;
      case VatPrepaymentStatus.known:
        return vatPrepaymentAmount ?? 0;
      case VatPrepaymentStatus.unset:
      case VatPrepaymentStatus.unknown:
        return null;
    }
  }

  /// 정확도 점수
  int get accuracyScore {
    final now = DateTime.now();
    final period = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(period, now);
    final monthsInPeriod = _vatElapsedMonths(period, now);

    final salesMonthsFilled =
        _salesList
            .where(
              (s) =>
                  !s.yearMonth.isBefore(period.start) &&
                  s.yearMonth.isBefore(completionEnd),
            )
            .length;

    return TaxCalculator.calculateAccuracy(
      salesMonthsFilled: salesMonthsFilled,
      totalMonths: monthsInPeriod,
      hasExpenses: _expensesList.isNotEmpty,
      hasDeemedPurchases: _deemedPurchases.isNotEmpty,
      lastUpdate: _lastUpdate,
    );
  }

  /// 매출 입력 완료도 (%)
  int get salesCompletionPercent {
    final now = DateTime.now();
    final period = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(period, now);
    final monthsInPeriod = _vatElapsedMonths(period, now);
    if (monthsInPeriod == 0) return 0;
    final filled =
        _salesList
            .where(
              (s) =>
                  !s.yearMonth.isBefore(period.start) &&
                  s.yearMonth.isBefore(completionEnd),
            )
            .length;
    return (filled / monthsInPeriod * 100).round().clamp(0, 100);
  }

  /// 지출 입력 완료도 (%)
  int get expenseCompletionPercent {
    return _expensesList.isNotEmpty ? 100 : 0;
  }

  /// 의제매입 입력 완료도 (%)
  int get deemedCompletionPercent {
    return _deemedPurchases.isNotEmpty ? 100 : 0;
  }

  /// 과거 이력 완료도 (%)
  int get historyCompletionPercent {
    int score = 0;
    if (_profile.previousVatAmount != null) score += 50;
    if (_profile.hasSpouse ||
        _profile.childrenCount > 0 ||
        _profile.supportsParents) {
      score += 50;
    }
    return score.clamp(0, 100);
  }

  /// 부가세 예측
  TaxPrediction get vatPrediction {
    final now = DateTime.now();
    final vatPeriod = _currentVatPeriod(now);
    final periodLabel = vatPeriod.label;
    final completionEnd = _vatCompletionEnd(vatPeriod, now);
    final monthsInPeriod = _vatElapsedMonths(vatPeriod, now);

    final periodSales =
        _salesList
            .where(
              (s) =>
                  !s.yearMonth.isBefore(vatPeriod.start) &&
                  s.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodExpenses =
        _expensesList
            .where(
              (e) =>
                  !e.yearMonth.isBefore(vatPeriod.start) &&
                  e.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodDeemed =
        _deemedPurchases
            .where(
              (d) =>
                  !d.yearMonth.isBefore(vatPeriod.start) &&
                  d.yearMonth.isBefore(completionEnd),
            )
            .toList();

    final filledMonths = periodSales.length.clamp(0, monthsInPeriod);
    final cardCreditUsedThisYear = _getCardCreditUsedForVatPeriod(vatPeriod);

    return TaxCalculator.calculateVat(
      business: _business,
      salesList: periodSales,
      expensesList: periodExpenses,
      deemedPurchases: periodDeemed,
      accuracyScore: accuracyScore,
      period: periodLabel,
      filledMonths: filledMonths,
      totalPeriodMonths: _vatTotalPeriodMonths(filledMonths),
      cardCreditUsedThisYear: cardCreditUsedThisYear,
      asOf: vatPeriod.constantsDate,
    );
  }

  VatBreakdown get vatBreakdown {
    final now = DateTime.now();
    final vatPeriod = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(vatPeriod, now);
    final monthsInPeriod = _vatElapsedMonths(vatPeriod, now);

    final periodSales =
        _salesList
            .where(
              (s) =>
                  !s.yearMonth.isBefore(vatPeriod.start) &&
                  s.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodExpenses =
        _expensesList
            .where(
              (e) =>
                  !e.yearMonth.isBefore(vatPeriod.start) &&
                  e.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodDeemed =
        _deemedPurchases
            .where(
              (d) =>
                  !d.yearMonth.isBefore(vatPeriod.start) &&
                  d.yearMonth.isBefore(completionEnd),
            )
            .toList();

    final filledMonths = periodSales.length.clamp(0, monthsInPeriod);
    final cardCreditUsedThisYear = _getCardCreditUsedForVatPeriod(vatPeriod);

    return TaxCalculator.computeVatBreakdown(
      business: _business,
      salesList: periodSales,
      expensesList: periodExpenses,
      deemedPurchases: periodDeemed,
      filledMonths: filledMonths,
      totalPeriodMonths: _vatTotalPeriodMonths(filledMonths),
      cardCreditUsedThisYear: cardCreditUsedThisYear,
      asOf: vatPeriod.constantsDate,
    );
  }

  /// 종소세 예측
  TaxPrediction get incomeTaxPrediction {
    final now = DateTime.now();
    final period = Formatters.getIncomeTaxPeriod(now);
    final yearStart = DateTime(now.year, 1, 1);

    final yearSales = _salesList
        .where((s) => !s.yearMonth.isBefore(yearStart))
        .toList();
    final yearExpenses = _expensesList
        .where((e) => !e.yearMonth.isBefore(yearStart))
        .toList();

    return TaxCalculator.calculateIncomeTax(
      business: _business,
      salesList: yearSales,
      expensesList: yearExpenses,
      profile: _profile,
      accuracyScore: accuracyScore,
      period: period,
      filledMonths: yearSales.length.clamp(0, now.month),
      totalPeriodMonths: 12,
    );
  }

  IncomeTaxBreakdown get incomeTaxBreakdown {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final yearSales = _salesList
        .where((s) => !s.yearMonth.isBefore(yearStart))
        .toList();
    final yearExpenses = _expensesList
        .where((e) => !e.yearMonth.isBefore(yearStart))
        .toList();

    return TaxCalculator.computeIncomeTaxBreakdown(
      business: _business,
      salesList: yearSales,
      expensesList: yearExpenses,
      profile: _profile,
      filledMonths: yearSales.length.clamp(0, now.month),
      totalPeriodMonths: 12,
    );
  }

  int _getCardCreditUsedForVatPeriod(VatPeriod vatPeriod) {
    // 2기(7~12월)에는 1기(1~6월) 공제를 먼저 반영해서 연간 한도 초과를 방지
    if (vatPeriod.half == 1) return 0;

    final year = vatPeriod.year;
    final firstHalfStart = DateTime(year, 1, 1);
    final secondHalfStart = DateTime(year, 7, 1);

    final firstHalfSales = _salesList
        .where(
          (s) =>
              !s.yearMonth.isBefore(firstHalfStart) &&
              s.yearMonth.isBefore(secondHalfStart),
        )
        .toList();
    final firstHalfExpenses = _expensesList
        .where(
          (e) =>
              !e.yearMonth.isBefore(firstHalfStart) &&
              e.yearMonth.isBefore(secondHalfStart),
        )
        .toList();
    final firstHalfDeemed = _deemedPurchases
        .where(
          (d) =>
              !d.yearMonth.isBefore(firstHalfStart) &&
              d.yearMonth.isBefore(secondHalfStart),
        )
        .toList();

    final firstHalfBreakdown = TaxCalculator.computeVatBreakdown(
      business: _business,
      salesList: firstHalfSales,
      expensesList: firstHalfExpenses,
      deemedPurchases: firstHalfDeemed,
      filledMonths: firstHalfSales.length.clamp(0, 6),
      totalPeriodMonths: _vatTotalPeriodMonths(
        firstHalfSales.length.clamp(0, 6),
      ),
      cardCreditUsedThisYear: 0,
      asOf: DateTime(year, 6, 30, 23, 59, 59),
    );

    return firstHalfBreakdown.cardIssuanceCredit;
  }

  /// 반기 총 매출
  int get halfYearTotalSales {
    final now = DateTime.now();
    final vatPeriod = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(vatPeriod, now);
    return _salesList
        .where(
          (s) =>
              !s.yearMonth.isBefore(vatPeriod.start) &&
              s.yearMonth.isBefore(completionEnd),
        )
        .fold<int>(0, (sum, s) => sum + s.totalSales);
  }

  /// 현재 반기 입력된 월 수
  int get vatFilledMonths {
    final now = DateTime.now();
    final vatPeriod = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(vatPeriod, now);
    final monthsInPeriod = _vatElapsedMonths(vatPeriod, now);
    return _salesList
        .where(
          (s) =>
              !s.yearMonth.isBefore(vatPeriod.start) &&
              s.yearMonth.isBefore(completionEnd),
        )
        .length
        .clamp(0, monthsInPeriod);
  }

  /// 항상 외삽 없는(scale=1) breakdown — 입력분만 원본 데이터
  VatBreakdown get vatBreakdownInputOnly {
    final now = DateTime.now();
    final vatPeriod = _currentVatPeriod(now);
    final completionEnd = _vatCompletionEnd(vatPeriod, now);
    final monthsInPeriod = _vatElapsedMonths(vatPeriod, now);

    final periodSales =
        _salesList
            .where(
              (s) =>
                  !s.yearMonth.isBefore(vatPeriod.start) &&
                  s.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodExpenses =
        _expensesList
            .where(
              (e) =>
                  !e.yearMonth.isBefore(vatPeriod.start) &&
                  e.yearMonth.isBefore(completionEnd),
            )
            .toList();
    final periodDeemed =
        _deemedPurchases
            .where(
              (d) =>
                  !d.yearMonth.isBefore(vatPeriod.start) &&
                  d.yearMonth.isBefore(completionEnd),
            )
            .toList();

    final filledMonths = periodSales.length.clamp(0, monthsInPeriod);
    final cardCreditUsedThisYear = _getCardCreditUsedForVatPeriod(vatPeriod);

    return TaxCalculator.computeVatBreakdown(
      business: _business,
      salesList: periodSales,
      expensesList: periodExpenses,
      deemedPurchases: periodDeemed,
      filledMonths: filledMonths,
      totalPeriodMonths: filledMonths <= 0 ? 1 : filledMonths,
      cardCreditUsedThisYear: cardCreditUsedThisYear,
      asOf: vatPeriod.constantsDate,
    );
  }

  int _vatTotalPeriodMonths(int filledMonths) {
    if (_vatExtrapolationEnabled) return 6;
    if (filledMonths <= 0) return 1;
    return filledMonths.clamp(1, 6);
  }
}
