enum PrecisionValueStatus {
  missing,
  complete,
  estimatedUser,
  estimatedIndustry,
  estimatedZero,
}

extension PrecisionValueStatusX on PrecisionValueStatus {
  double get scoreFactor {
    switch (this) {
      case PrecisionValueStatus.complete:
        return 1.0;
      case PrecisionValueStatus.estimatedUser:
        return 0.7;
      case PrecisionValueStatus.estimatedIndustry:
        return 0.5;
      case PrecisionValueStatus.estimatedZero:
      case PrecisionValueStatus.missing:
        return 0.0;
    }
  }

  double get rangePercent {
    switch (this) {
      case PrecisionValueStatus.estimatedUser:
        return 0.10;
      case PrecisionValueStatus.estimatedIndustry:
        return 0.20;
      default:
        return 0.0;
    }
  }

  bool get isEstimated {
    return this == PrecisionValueStatus.estimatedUser ||
        this == PrecisionValueStatus.estimatedIndustry ||
        this == PrecisionValueStatus.estimatedZero;
  }

  String get label {
    switch (this) {
      case PrecisionValueStatus.complete:
        return '완료';
      case PrecisionValueStatus.estimatedUser:
        return '추정(사용자)';
      case PrecisionValueStatus.estimatedIndustry:
        return '추정(업종)';
      case PrecisionValueStatus.estimatedZero:
        return '추정 0';
      case PrecisionValueStatus.missing:
        return '미입력';
    }
  }
}

enum BusinessInputMode { annual, monthly }

enum VatInclusionChoice { included, excluded, unknown }

enum SelectionState { unset, yes, no, unknown }

extension SelectionStateX on SelectionState {
  PrecisionValueStatus get status {
    switch (this) {
      case SelectionState.yes:
      case SelectionState.no:
        return PrecisionValueStatus.complete;
      case SelectionState.unknown:
        return PrecisionValueStatus.estimatedUser;
      case SelectionState.unset:
        return PrecisionValueStatus.missing;
    }
  }
}

class NumericField {
  final int? value;
  final PrecisionValueStatus status;

  const NumericField({this.value, this.status = PrecisionValueStatus.missing});

  static const missing = NumericField();

  int get safeValue => value ?? 0;

  bool get hasValue => value != null;

  NumericField copyWith({
    int? value,
    bool clearValue = false,
    PrecisionValueStatus? status,
  }) {
    return NumericField(
      value: clearValue ? null : (value ?? this.value),
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'status': status.name};

  factory NumericField.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    final status = PrecisionValueStatus.values.firstWhere(
      (item) => item.name == rawStatus,
      orElse: () => PrecisionValueStatus.missing,
    );
    return NumericField(value: json['value'] as int?, status: status);
  }
}

class MonthlyBusinessInput {
  final int month;
  final NumericField sales;
  final NumericField expenses;

  const MonthlyBusinessInput({
    required this.month,
    this.sales = NumericField.missing,
    this.expenses = NumericField.missing,
  });

  MonthlyBusinessInput copyWith({
    int? month,
    NumericField? sales,
    NumericField? expenses,
  }) {
    return MonthlyBusinessInput(
      month: month ?? this.month,
      sales: sales ?? this.sales,
      expenses: expenses ?? this.expenses,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'sales': sales.toJson(),
    'expenses': expenses.toJson(),
  };

  factory MonthlyBusinessInput.fromJson(Map<String, dynamic> json) {
    return MonthlyBusinessInput(
      month: json['month'] as int? ?? 1,
      sales: json['sales'] is Map<String, dynamic>
          ? NumericField.fromJson(json['sales'] as Map<String, dynamic>)
          : NumericField.missing,
      expenses: json['expenses'] is Map<String, dynamic>
          ? NumericField.fromJson(json['expenses'] as Map<String, dynamic>)
          : NumericField.missing,
    );
  }
}

class IncomeCategoryInput {
  final bool enabled;
  final NumericField incomeAmount;
  final NumericField withholdingTax;

  const IncomeCategoryInput({
    this.enabled = false,
    this.incomeAmount = NumericField.missing,
    this.withholdingTax = NumericField.missing,
  });

  IncomeCategoryInput copyWith({
    bool? enabled,
    NumericField? incomeAmount,
    NumericField? withholdingTax,
  }) {
    return IncomeCategoryInput(
      enabled: enabled ?? this.enabled,
      incomeAmount: incomeAmount ?? this.incomeAmount,
      withholdingTax: withholdingTax ?? this.withholdingTax,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'incomeAmount': incomeAmount.toJson(),
    'withholdingTax': withholdingTax.toJson(),
  };

  factory IncomeCategoryInput.fromJson(Map<String, dynamic> json) {
    return IncomeCategoryInput(
      enabled: json['enabled'] as bool? ?? false,
      incomeAmount: json['incomeAmount'] is Map<String, dynamic>
          ? NumericField.fromJson(json['incomeAmount'] as Map<String, dynamic>)
          : NumericField.missing,
      withholdingTax: json['withholdingTax'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['withholdingTax'] as Map<String, dynamic>,
            )
          : NumericField.missing,
    );
  }
}

class PrecisionTaxDraft {
  final int taxYear;
  final bool useEstimatedYearConstants;

  final bool hasBusinessIncome;
  final bool hasLaborIncome;
  final bool hasPensionIncome;
  final bool hasFinancialIncome;
  final bool hasOtherIncome;

  final BusinessInputMode businessInputMode;
  final bool bookkeeping;
  final bool fillMissingMonths;

  final NumericField annualSales;
  final VatInclusionChoice annualSalesVatMode;
  final NumericField annualExpenses;
  final List<MonthlyBusinessInput> monthlyBusinessInputs;

  final IncomeCategoryInput laborIncome;
  final IncomeCategoryInput pensionIncome;
  final IncomeCategoryInput financialIncome;
  final IncomeCategoryInput otherIncome;
  final SelectionState financialOverTwentyMillion;

  final SelectionState spouseSelection;
  final NumericField childrenCount;
  final NumericField parentsCount;
  final SelectionState yellowUmbrellaSelection;
  final NumericField yellowUmbrellaAnnualPayment;
  final NumericField additionalTaxCredit;

  final SelectionState midtermPrepaymentSelection;
  final NumericField midtermPrepayment;
  final SelectionState otherPrepaymentSelection;
  final NumericField otherPrepayment;

  const PrecisionTaxDraft({
    required this.taxYear,
    this.useEstimatedYearConstants = false,
    this.hasBusinessIncome = true,
    this.hasLaborIncome = false,
    this.hasPensionIncome = false,
    this.hasFinancialIncome = false,
    this.hasOtherIncome = false,
    this.businessInputMode = BusinessInputMode.annual,
    this.bookkeeping = true,
    this.fillMissingMonths = false,
    this.annualSales = NumericField.missing,
    this.annualSalesVatMode = VatInclusionChoice.included,
    this.annualExpenses = NumericField.missing,
    this.monthlyBusinessInputs = const [],
    this.laborIncome = const IncomeCategoryInput(),
    this.pensionIncome = const IncomeCategoryInput(),
    this.financialIncome = const IncomeCategoryInput(),
    this.otherIncome = const IncomeCategoryInput(),
    this.financialOverTwentyMillion = SelectionState.unset,
    this.spouseSelection = SelectionState.no,
    this.childrenCount = const NumericField(
      value: 0,
      status: PrecisionValueStatus.complete,
    ),
    this.parentsCount = const NumericField(
      value: 0,
      status: PrecisionValueStatus.complete,
    ),
    this.yellowUmbrellaSelection = SelectionState.no,
    this.yellowUmbrellaAnnualPayment = const NumericField(
      value: 0,
      status: PrecisionValueStatus.complete,
    ),
    this.additionalTaxCredit = const NumericField(
      value: 0,
      status: PrecisionValueStatus.complete,
    ),
    this.midtermPrepaymentSelection = SelectionState.unset,
    this.midtermPrepayment = NumericField.missing,
    this.otherPrepaymentSelection = SelectionState.unset,
    this.otherPrepayment = NumericField.missing,
  });

  factory PrecisionTaxDraft.initial({required DateTime now}) {
    final year = now.year - 1;
    return PrecisionTaxDraft(
      taxYear: year,
      monthlyBusinessInputs: List<MonthlyBusinessInput>.generate(
        12,
        (index) => MonthlyBusinessInput(month: index + 1),
      ),
    );
  }

  PrecisionTaxDraft copyWith({
    int? taxYear,
    bool? useEstimatedYearConstants,
    bool? hasBusinessIncome,
    bool? hasLaborIncome,
    bool? hasPensionIncome,
    bool? hasFinancialIncome,
    bool? hasOtherIncome,
    BusinessInputMode? businessInputMode,
    bool? bookkeeping,
    bool? fillMissingMonths,
    NumericField? annualSales,
    VatInclusionChoice? annualSalesVatMode,
    NumericField? annualExpenses,
    List<MonthlyBusinessInput>? monthlyBusinessInputs,
    IncomeCategoryInput? laborIncome,
    IncomeCategoryInput? pensionIncome,
    IncomeCategoryInput? financialIncome,
    IncomeCategoryInput? otherIncome,
    SelectionState? financialOverTwentyMillion,
    SelectionState? spouseSelection,
    NumericField? childrenCount,
    NumericField? parentsCount,
    SelectionState? yellowUmbrellaSelection,
    NumericField? yellowUmbrellaAnnualPayment,
    NumericField? additionalTaxCredit,
    SelectionState? midtermPrepaymentSelection,
    NumericField? midtermPrepayment,
    SelectionState? otherPrepaymentSelection,
    NumericField? otherPrepayment,
  }) {
    return PrecisionTaxDraft(
      taxYear: taxYear ?? this.taxYear,
      useEstimatedYearConstants:
          useEstimatedYearConstants ?? this.useEstimatedYearConstants,
      hasBusinessIncome: hasBusinessIncome ?? this.hasBusinessIncome,
      hasLaborIncome: hasLaborIncome ?? this.hasLaborIncome,
      hasPensionIncome: hasPensionIncome ?? this.hasPensionIncome,
      hasFinancialIncome: hasFinancialIncome ?? this.hasFinancialIncome,
      hasOtherIncome: hasOtherIncome ?? this.hasOtherIncome,
      businessInputMode: businessInputMode ?? this.businessInputMode,
      bookkeeping: bookkeeping ?? this.bookkeeping,
      fillMissingMonths: fillMissingMonths ?? this.fillMissingMonths,
      annualSales: annualSales ?? this.annualSales,
      annualSalesVatMode: annualSalesVatMode ?? this.annualSalesVatMode,
      annualExpenses: annualExpenses ?? this.annualExpenses,
      monthlyBusinessInputs:
          monthlyBusinessInputs ?? this.monthlyBusinessInputs,
      laborIncome: laborIncome ?? this.laborIncome,
      pensionIncome: pensionIncome ?? this.pensionIncome,
      financialIncome: financialIncome ?? this.financialIncome,
      otherIncome: otherIncome ?? this.otherIncome,
      financialOverTwentyMillion:
          financialOverTwentyMillion ?? this.financialOverTwentyMillion,
      spouseSelection: spouseSelection ?? this.spouseSelection,
      childrenCount: childrenCount ?? this.childrenCount,
      parentsCount: parentsCount ?? this.parentsCount,
      yellowUmbrellaSelection:
          yellowUmbrellaSelection ?? this.yellowUmbrellaSelection,
      yellowUmbrellaAnnualPayment:
          yellowUmbrellaAnnualPayment ?? this.yellowUmbrellaAnnualPayment,
      additionalTaxCredit: additionalTaxCredit ?? this.additionalTaxCredit,
      midtermPrepaymentSelection:
          midtermPrepaymentSelection ?? this.midtermPrepaymentSelection,
      midtermPrepayment: midtermPrepayment ?? this.midtermPrepayment,
      otherPrepaymentSelection:
          otherPrepaymentSelection ?? this.otherPrepaymentSelection,
      otherPrepayment: otherPrepayment ?? this.otherPrepayment,
    );
  }

  MonthlyBusinessInput monthInput(int month) {
    return monthlyBusinessInputs.firstWhere(
      (item) => item.month == month,
      orElse: () => MonthlyBusinessInput(month: month),
    );
  }

  PrecisionTaxDraft updateMonthInput({
    required int month,
    NumericField? sales,
    NumericField? expenses,
  }) {
    final next = monthlyBusinessInputs.map((item) {
      if (item.month != month) return item;
      return item.copyWith(
        sales: sales ?? item.sales,
        expenses: expenses ?? item.expenses,
      );
    }).toList()..sort((a, b) => a.month.compareTo(b.month));
    return copyWith(monthlyBusinessInputs: next);
  }

  Map<String, dynamic> toJson() => {
    'taxYear': taxYear,
    'useEstimatedYearConstants': useEstimatedYearConstants,
    'hasBusinessIncome': hasBusinessIncome,
    'hasLaborIncome': hasLaborIncome,
    'hasPensionIncome': hasPensionIncome,
    'hasFinancialIncome': hasFinancialIncome,
    'hasOtherIncome': hasOtherIncome,
    'businessInputMode': businessInputMode.name,
    'bookkeeping': bookkeeping,
    'fillMissingMonths': fillMissingMonths,
    'annualSales': annualSales.toJson(),
    'annualSalesVatMode': annualSalesVatMode.name,
    'annualExpenses': annualExpenses.toJson(),
    'monthlyBusinessInputs': monthlyBusinessInputs
        .map((item) => item.toJson())
        .toList(),
    'laborIncome': laborIncome.toJson(),
    'pensionIncome': pensionIncome.toJson(),
    'financialIncome': financialIncome.toJson(),
    'otherIncome': otherIncome.toJson(),
    'financialOverTwentyMillion': financialOverTwentyMillion.name,
    'spouseSelection': spouseSelection.name,
    'childrenCount': childrenCount.toJson(),
    'parentsCount': parentsCount.toJson(),
    'yellowUmbrellaSelection': yellowUmbrellaSelection.name,
    'yellowUmbrellaAnnualPayment': yellowUmbrellaAnnualPayment.toJson(),
    'additionalTaxCredit': additionalTaxCredit.toJson(),
    'midtermPrepaymentSelection': midtermPrepaymentSelection.name,
    'midtermPrepayment': midtermPrepayment.toJson(),
    'otherPrepaymentSelection': otherPrepaymentSelection.name,
    'otherPrepayment': otherPrepayment.toJson(),
  };

  factory PrecisionTaxDraft.fromJson(Map<String, dynamic> json) {
    final monthlyInputsRaw = json['monthlyBusinessInputs'] as List<dynamic>?;
    final monthlyInputs =
        monthlyInputsRaw
            ?.whereType<Map>()
            .map(
              (item) => MonthlyBusinessInput.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList() ??
        List<MonthlyBusinessInput>.generate(
          12,
          (index) => MonthlyBusinessInput(month: index + 1),
        );

    BusinessInputMode parseBusinessMode(String? raw) {
      return BusinessInputMode.values.firstWhere(
        (item) => item.name == raw,
        orElse: () => BusinessInputMode.annual,
      );
    }

    VatInclusionChoice parseVatMode(String? raw) {
      return VatInclusionChoice.values.firstWhere(
        (item) => item.name == raw,
        orElse: () => VatInclusionChoice.included,
      );
    }

    SelectionState parseSelection(String? raw) {
      return SelectionState.values.firstWhere(
        (item) => item.name == raw,
        orElse: () => SelectionState.unset,
      );
    }

    return PrecisionTaxDraft(
      taxYear: json['taxYear'] as int? ?? DateTime.now().year - 1,
      useEstimatedYearConstants:
          json['useEstimatedYearConstants'] as bool? ?? false,
      hasBusinessIncome: json['hasBusinessIncome'] as bool? ?? true,
      hasLaborIncome: json['hasLaborIncome'] as bool? ?? false,
      hasPensionIncome: json['hasPensionIncome'] as bool? ?? false,
      hasFinancialIncome: json['hasFinancialIncome'] as bool? ?? false,
      hasOtherIncome: json['hasOtherIncome'] as bool? ?? false,
      businessInputMode: parseBusinessMode(
        json['businessInputMode'] as String?,
      ),
      bookkeeping: json['bookkeeping'] as bool? ?? true,
      fillMissingMonths: json['fillMissingMonths'] as bool? ?? false,
      annualSales: json['annualSales'] is Map<String, dynamic>
          ? NumericField.fromJson(json['annualSales'] as Map<String, dynamic>)
          : NumericField.missing,
      annualSalesVatMode: parseVatMode(json['annualSalesVatMode'] as String?),
      annualExpenses: json['annualExpenses'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['annualExpenses'] as Map<String, dynamic>,
            )
          : NumericField.missing,
      monthlyBusinessInputs: monthlyInputs,
      laborIncome: json['laborIncome'] is Map<String, dynamic>
          ? IncomeCategoryInput.fromJson(
              json['laborIncome'] as Map<String, dynamic>,
            )
          : const IncomeCategoryInput(),
      pensionIncome: json['pensionIncome'] is Map<String, dynamic>
          ? IncomeCategoryInput.fromJson(
              json['pensionIncome'] as Map<String, dynamic>,
            )
          : const IncomeCategoryInput(),
      financialIncome: json['financialIncome'] is Map<String, dynamic>
          ? IncomeCategoryInput.fromJson(
              json['financialIncome'] as Map<String, dynamic>,
            )
          : const IncomeCategoryInput(),
      otherIncome: json['otherIncome'] is Map<String, dynamic>
          ? IncomeCategoryInput.fromJson(
              json['otherIncome'] as Map<String, dynamic>,
            )
          : const IncomeCategoryInput(),
      financialOverTwentyMillion: parseSelection(
        json['financialOverTwentyMillion'] as String?,
      ),
      spouseSelection: parseSelection(json['spouseSelection'] as String?),
      childrenCount: json['childrenCount'] is Map<String, dynamic>
          ? NumericField.fromJson(json['childrenCount'] as Map<String, dynamic>)
          : const NumericField(value: 0, status: PrecisionValueStatus.complete),
      parentsCount: json['parentsCount'] is Map<String, dynamic>
          ? NumericField.fromJson(json['parentsCount'] as Map<String, dynamic>)
          : const NumericField(value: 0, status: PrecisionValueStatus.complete),
      yellowUmbrellaSelection: parseSelection(
        json['yellowUmbrellaSelection'] as String?,
      ),
      yellowUmbrellaAnnualPayment:
          json['yellowUmbrellaAnnualPayment'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['yellowUmbrellaAnnualPayment'] as Map<String, dynamic>,
            )
          : const NumericField(value: 0, status: PrecisionValueStatus.complete),
      additionalTaxCredit: json['additionalTaxCredit'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['additionalTaxCredit'] as Map<String, dynamic>,
            )
          : const NumericField(value: 0, status: PrecisionValueStatus.complete),
      midtermPrepaymentSelection: parseSelection(
        json['midtermPrepaymentSelection'] as String?,
      ),
      midtermPrepayment: json['midtermPrepayment'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['midtermPrepayment'] as Map<String, dynamic>,
            )
          : NumericField.missing,
      otherPrepaymentSelection: parseSelection(
        json['otherPrepaymentSelection'] as String?,
      ),
      otherPrepayment: json['otherPrepayment'] is Map<String, dynamic>
          ? NumericField.fromJson(
              json['otherPrepayment'] as Map<String, dynamic>,
            )
          : NumericField.missing,
    );
  }
}
