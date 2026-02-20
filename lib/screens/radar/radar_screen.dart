import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../models/tax_prediction.dart';
import '../../providers/business_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/accuracy_gauge.dart';
import '../../widgets/glossary_help_text.dart';
import '../../widgets/season_banner.dart';
import '../../widgets/tax_calendar_card.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final vatPrediction = provider.vatPrediction;
    final incomeTaxPrediction = provider.incomeTaxPrediction;
    final nextVatDeadline = Formatters.getNextVatDeadline();
    final nextIncomeDeadline = Formatters.getNextIncomeTaxDeadline();

    final now = DateTime.now();
    final vatDaysLeft = nextVatDeadline.difference(now).inDays;
    final incomeDaysLeft = nextIncomeDeadline.difference(now).inDays;
    final showVatBanner = vatDaysLeft <= 30 && vatDaysLeft >= 0;
    final showIncomeBanner = incomeDaysLeft <= 30 && incomeDaysLeft >= 0;

    final freshnessPercent = _calcFreshness(provider.lastUpdate);
    final vatPeriod = provider.vatPeriod.label;
    final accuracyScore = provider.accuracyScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _buildHeader(),

              // ── Greeting ──
              _buildGreeting(vatPeriod),
              const SizedBox(height: 24),

              // ── Season banners ──
              if (showVatBanner) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SeasonBanner(
                    taxType: '부가세',
                    deadline: nextVatDeadline,
                    onTap: () => context.push('/data'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (showIncomeBanner) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SeasonBanner(
                    taxType: '종소세',
                    deadline: nextIncomeDeadline,
                    onTap: () => context.push('/data'),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── VAT 카드 (Primary) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildVatCard(
                  context,
                  provider,
                  vatPrediction,
                  nextVatDeadline,
                  accuracyScore,
                ),
              ),
              const SizedBox(height: 16),

              // ── 종소세 카드 (Secondary) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildIncomeTaxCard(
                  context,
                  incomeTaxPrediction,
                  nextIncomeDeadline,
                ),
              ),
              const SizedBox(height: 24),

              // ── 이번 달 현황 (가로 스크롤) ──
              _buildMonthlyMetrics(context, provider, now),
              const SizedBox(height: 24),

              // ── 정확도 게이지 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AccuracyGauge(
                  overallPercent: accuracyScore,
                  salesPercent: provider.salesCompletionPercent,
                  expensePercent: provider.expenseCompletionPercent,
                  deemedPercent: provider.deemedCompletionPercent,
                  freshnessPercent: freshnessPercent,
                  onItemTap: (type) {
                    switch (type) {
                      case 'sales':
                        context.push('/data/sales-input');
                      case 'expense':
                        context.push('/data/expense-input');
                      case 'deemed':
                        context.push('/data/deemed-purchase');
                      case 'freshness':
                        context.go('/data');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── 세금 캘린더 ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TaxCalendarCard(),
              ),
              const SizedBox(height: 16),

              // ── 절세 팁 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTaxTip(provider),
              ),
              const SizedBox(height: 16),

              // ── 액션 버튼 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.calculate_outlined,
                        label: '정밀 종소세',
                        onTap: () => context.push('/precision-tax'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.science_outlined,
                        label: '시뮬레이터',
                        onTap: () => context.push('/simulator'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, size: 28, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '세금레이더',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 24,
                      color: AppColors.textHint,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Greeting
  // ────────────────────────────────────────────

  Widget _buildGreeting(String vatPeriod) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  vatPeriod,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 인사말
          Text(
            '사장님,',
            style: GoogleFonts.notoSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          Text(
            '다음 부가세 예상액이에요',
            style: GoogleFonts.notoSans(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // VAT 카드 (Primary)
  // ────────────────────────────────────────────

  Widget _buildVatCard(
    BuildContext context,
    BusinessProvider provider,
    TaxPrediction prediction,
    DateTime deadline,
    int accuracyScore,
  ) {
    final helpMode = context.select<BusinessProvider, bool>(
      (p) => p.glossaryHelpModeEnabled,
    );
    final dateStr =
        '${deadline.year}.${deadline.month.toString().padLeft(2, '0')}.${deadline.day.toString().padLeft(2, '0')}';
    final ddayText = Formatters.formatDday(deadline);

    return GestureDetector(
      onTap: () => context.push('/tax-detail/vat'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 부가세 라벨 + 정확도 배지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GlossaryHelpText(
                      label: '부가세',
                      termId: 'V01',
                      dense: true,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!helpMode) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '정확도 ${prediction.accuracyScore}%',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 금액 (accent gold) — 기납부 반영
            Builder(
              builder: (context) {
                final prepayment = provider.vatPrepaymentEffectiveAmount;
                String text;
                if (prepayment == null) {
                  text = prediction.isRefund
                      ? '환급 최소 ${Formatters.toManWon(prediction.predictedMin)}원'
                      : '최대 ${Formatters.toManWon(prediction.predictedMax)}원';
                } else {
                  final decisionSignedMid =
                      prediction.isRefund ? -prediction.midPoint : prediction.midPoint;
                  final actualSignedMid = decisionSignedMid - prepayment;
                  if (actualSignedMid < 0) {
                    text =
                        '환급 약 ${Formatters.toManWon(-actualSignedMid)}원';
                  } else {
                    text =
                        '추가 약 ${Formatters.toManWon(actualSignedMid)}원';
                  }
                }
                return Text(
                  text,
                  style: GoogleFonts.notoSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 납부 기한 + 상세보기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '납부 기한',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr 까지',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => context.push('/tax-detail/vat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '상세보기',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 프로그레스 바
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '예상 납부일 $ddayText',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  '$accuracyScore% 분석 완료',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: accuracyScore / 100,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 종소세 카드 (Secondary)
  // ────────────────────────────────────────────

  Widget _buildIncomeTaxCard(
    BuildContext context,
    TaxPrediction prediction,
    DateTime deadline,
  ) {
    final dateStr =
        '${deadline.year}.${deadline.month.toString().padLeft(2, '0')}.${deadline.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => context.push('/tax-detail/income_tax'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlossaryHelpText(
                      label: '종합소득세',
                      termId: 'T01',
                      dense: true,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '약 ${Formatters.toManWon(prediction.midPoint)}원',
                      style: GoogleFonts.notoSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '정확도 ${prediction.accuracyScore}%',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$dateStr 납부',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 이번 달 현황 (가로 스크롤 미니 카드)
  // ────────────────────────────────────────────

  Widget _buildMonthlyMetrics(
    BuildContext context,
    BusinessProvider provider,
    DateTime now,
  ) {
    final currentMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(now.year, now.month - 1, 1);

    final currentSales = provider.getSalesForMonth(currentMonth);
    final prevSales = provider.getSalesForMonth(prevMonth);

    // 이번 달 경비
    final currentExpenses = provider.expensesList
        .where(
          (e) => e.yearMonth.year == now.year && e.yearMonth.month == now.month,
        )
        .fold<int>(0, (sum, e) => sum + e.totalExpenses);

    // 의제매입 공제액
    final deemedCredit = provider.vatBreakdown.deemedPurchaseCredit;

    // 전월 대비 변화율
    String? salesChangeText;
    Color? salesChangeColor;
    if (currentSales != null && prevSales != null && prevSales.totalSales > 0) {
      final change =
          ((currentSales.totalSales - prevSales.totalSales) /
                  prevSales.totalSales *
                  100)
              .round();
      if (change >= 0) {
        salesChangeText = '지난달 +$change%';
        salesChangeColor = AppColors.success;
      } else {
        salesChangeText = '지난달 $change%';
        salesChangeColor = AppColors.danger;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 달 현황',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      '전체보기',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 가로 스크롤 카드
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _MetricMiniCard(
                icon: Icons.payments_outlined,
                iconBgColor: AppColors.success.withValues(alpha: 0.1),
                iconColor: AppColors.success,
                label: '매출',
                value: currentSales != null
                    ? Formatters.toManWon(currentSales.totalSales)
                    : '미입력',
                subText: salesChangeText,
                subColor: salesChangeColor,
                showTrendIcon: salesChangeColor == AppColors.success,
                onTap: () => context.push('/data/sales-input'),
              ),
              const SizedBox(width: 12),
              _MetricMiniCard(
                icon: Icons.shopping_cart_outlined,
                iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                iconColor: AppColors.warning,
                label: '매입 경비',
                value: currentExpenses > 0
                    ? Formatters.toManWon(currentExpenses)
                    : '미입력',
                subText: currentExpenses > 0 ? '세금계산서 발행분' : null,
                onTap: () => context.push('/data/expense-input'),
              ),
              const SizedBox(width: 12),
              _MetricMiniCard(
                icon: Icons.percent,
                iconBgColor: AppColors.primary.withValues(alpha: 0.1),
                iconColor: AppColors.primary,
                label: '의제매입',
                value: deemedCredit > 0
                    ? Formatters.toManWon(deemedCredit)
                    : '미입력',
                subText: deemedCredit > 0 ? '공제 예상액' : null,
                subColor: deemedCredit > 0 ? AppColors.primary : null,
                onTap: () => context.push('/data/deemed-purchase'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // 절세 팁
  // ────────────────────────────────────────────

  Widget _buildTaxTip(BusinessProvider provider) {
    String tipText;
    if (provider.expenseCompletionPercent == 0) {
      tipText = '경비를 입력하면 종합소득세 예측이 더 정확해져요. 지금 바로 매입 자료를 등록해보세요.';
    } else if (provider.deemedCompletionPercent == 0) {
      tipText = '면세 매입 자료를 등록하면 의제매입세액공제를 받을 수 있어요. 식재료비를 확인해보세요.';
    } else {
      tipText = '이번 달 매입 자료를 3일 내로 홈택스에 등록하면 약 12만원의 추가 공제 혜택을 받을 수 있어요.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '절세 팁',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipText,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // 최신성 계산
  // ────────────────────────────────────────────

  int _calcFreshness(DateTime? lastUpdate) {
    if (lastUpdate == null) return 0;
    final daysSince = DateTime.now().difference(lastUpdate).inDays;
    if (daysSince <= 7) return 100;
    if (daysSince <= 30) return 67;
    if (daysSince <= 90) return 33;
    return 0;
  }
}

// ══════════════════════════════════════════════
// 이번 달 현황 미니 카드
// ══════════════════════════════════════════════

class _MetricMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final String? subText;
  final Color? subColor;
  final bool showTrendIcon;
  final VoidCallback? onTap;

  const _MetricMiniCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subText,
    this.subColor,
    this.showTrendIcon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 아이콘 + 라벨
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, size: 18, color: iconColor)),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            // 금액 + 부가 텍스트
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: value == '미입력'
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
                if (subText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (showTrendIcon)
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: subColor ?? AppColors.textHint,
                        ),
                      if (showTrendIcon) const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          subText!,
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: subColor ?? AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// 액션 버튼
// ══════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
