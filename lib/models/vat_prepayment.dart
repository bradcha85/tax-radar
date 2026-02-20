enum VatPrepaymentStatus {
  unset,
  none,
  known,
  unknown,
}

extension VatPrepaymentStatusX on VatPrepaymentStatus {
  String get label {
    switch (this) {
      case VatPrepaymentStatus.none:
        return '없음';
      case VatPrepaymentStatus.known:
        return '있음';
      case VatPrepaymentStatus.unknown:
        return '모르겠어요';
      case VatPrepaymentStatus.unset:
        return '미입력';
    }
  }
}

