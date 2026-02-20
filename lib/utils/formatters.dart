import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 숫자 입력 시 천 단위 콤마 자동 포맷 (여러 화면에서 공유)
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll(',', '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;

    final formatted = Formatters.formatWon(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class Formatters {
  Formatters._();

  static final _numberFormat = NumberFormat('#,###');
  static final _monthFormat = DateFormat('yyyy.MM');

  /// 원 단위를 만원 단위 문자열로 변환 (예: 2400000 → "240만")
  static String toManWon(int won) {
    final man = won / 10000;
    if (man >= 10000) {
      final eok = man / 10000;
      if (eok == eok.roundToDouble()) {
        return '${eok.round()}억';
      }
      return '${eok.toStringAsFixed(1)}억';
    }
    if (man == man.roundToDouble()) {
      return '${man.round()}만';
    }
    return '${man.toStringAsFixed(0)}만';
  }

  /// 원 단위를 만원 단위 + "원" 문자열로 변환 (예: 2400000 → "240만 원")
  static String toManWonWithUnit(int won) {
    return '${toManWon(won)} 원';
  }

  /// 원 단위를 #,### 포맷 (예: 24000000 → "24,000,000")
  static String formatWon(int won) {
    return _numberFormat.format(won);
  }

  /// 원 단위를 #,###원 포맷 (예: 24000000 → "24,000,000원")
  static String formatWonWithUnit(int won) {
    return '${formatWon(won)}원';
  }

  /// DateTime을 "2025.01" 형식으로
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  /// D-day 문자열 (예: D-30, D-day, D+5)
  static String formatDday(DateTime targetDate) {
    final diff = targetDate.difference(DateTime.now()).inDays;
    if (diff > 0) return 'D-$diff';
    if (diff == 0) return 'D-day';
    return 'D+${-diff}';
  }

  /// 퍼센트 포맷 (예: 53 → "53%")
  static String formatPercent(int value) {
    return '$value%';
  }

  /// 부가세 기수 (1기/2기)
  static String getVatPeriod(DateTime date) {
    final year = date.year;
    final half = date.month <= 6 ? '1기' : '2기';
    return '$year년 $half';
  }

  /// 다음 납부(확정신고) 기준으로 해석한 부가세 과세기간 정보
  ///
  /// - 7/25 납부분: 해당 연도 1기(1~6월)
  /// - 1/25 납부분: 전년도 2기(7~12월)
  static VatPeriod resolveVatPeriod({DateTime? now}) {
    final current = now ?? DateTime.now();
    final deadline = getNextVatDeadline(now: current);

    // 1/25 납부 = 전년도 2기(7~12월)
    if (deadline.month == 1) {
      final year = deadline.year - 1;
      return VatPeriod(
        year: year,
        half: 2,
        start: DateTime(year, 7, 1),
        end: DateTime(year + 1, 1, 1),
        deadline: deadline,
      );
    }

    // 7/25 납부 = 해당 연도 1기(1~6월)
    final year = deadline.year;
    return VatPeriod(
      year: year,
      half: 1,
      start: DateTime(year, 1, 1),
      end: DateTime(year, 7, 1),
      deadline: deadline,
    );
  }

  /// 종소세 기간
  static String getIncomeTaxPeriod(DateTime date) {
    return '${date.year}년';
  }

  /// 다음 부가세 납부일
  static DateTime getNextVatDeadline({DateTime? now}) {
    final current = now ?? DateTime.now();
    final year = current.year;

    // 1기 확정: 7/25, 2기 확정: 다음해 1/25
    final deadlines = [
      DateTime(year, 1, 25),
      DateTime(year, 7, 25),
      DateTime(year + 1, 1, 25),
    ];

    for (final d in deadlines) {
      if (d.isAfter(current)) return d;
    }
    return DateTime(year + 1, 7, 25);
  }

  /// 다음 종소세 납부일
  static DateTime getNextIncomeTaxDeadline() {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, 5, 31);
    if (thisYear.isAfter(now)) return thisYear;
    return DateTime(now.year + 1, 5, 31);
  }
}

class VatPeriod {
  final int year;
  final int half; // 1 or 2
  final DateTime start;
  final DateTime end; // exclusive
  final DateTime deadline;

  const VatPeriod({
    required this.year,
    required this.half,
    required this.start,
    required this.end,
    required this.deadline,
  });

  String get key => '$year-$half';

  String get label => '$year년 ${half == 1 ? '1기' : '2기'}';

  String get monthRangeLabel => half == 1 ? '1월~6월' : '7월~12월';

  int get totalMonths => 6;

  /// 상수(공제율/한도 등)를 적용할 기준 날짜. 거래가 발생한 연도 안에서 판단한다.
  DateTime get constantsDate => half == 1
      ? DateTime(year, 6, 30, 23, 59, 59)
      : DateTime(year, 12, 31, 23, 59, 59);
}
