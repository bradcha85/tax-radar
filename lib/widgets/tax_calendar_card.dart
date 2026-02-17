import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'notion_card.dart';

class TaxEvent {
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final String? description;

  const TaxEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    this.description,
  });
}

class TaxCalendarCard extends StatefulWidget {
  final VoidCallback? onTap;

  const TaxCalendarCard({super.key, this.onTap});

  @override
  State<TaxCalendarCard> createState() => _TaxCalendarCardState();
}

class _TaxCalendarCardState extends State<TaxCalendarCard> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  List<TaxEvent> _getAllEvents() {
    final year = DateTime.now().year;
    return [
      TaxEvent(
        title: '부가세 1기 예정고지',
        subtitle: '1.1~3.31 납부',
        date: DateTime(year, 4, 25),
        color: AppColors.primary,
        description:
            '국세청이 직전 반기 확정 납부세액의 50%를 고지서로 보내줘요.\n\n'
            '직접 신고할 필요 없이 고지된 금액만 납부하면 돼요. '
            '나중에 7월 확정신고 때 이미 낸 금액은 차감됩니다.',
      ),
      TaxEvent(
        title: '종합소득세 신고·납부',
        subtitle: '$year년 귀속',
        date: DateTime(year, 5, 31),
        color: AppColors.notionPurple,
        description:
            '전년도(${year - 1}년) 1년간의 모든 소득을 합산하여 신고·납부해요.\n\n'
            '사업소득·근로소득·금융소득 등을 합산해서 누진세율(6%~45%)이 적용됩니다. '
            '홈택스에서 직접 신고하거나 세무사에게 대리 신고를 맡길 수 있어요.',
      ),
      TaxEvent(
        title: '부가세 1기 확정 신고',
        subtitle: '1.1~6.30 신고·납부',
        date: DateTime(year, 7, 25),
        color: AppColors.primary,
        description:
            '1월~6월까지의 실제 매출·매입 자료를 직접 홈택스에 신고해요.\n\n'
            '4월에 낸 예정고지 세액은 차감되므로, 나머지 차액만 납부하면 됩니다. '
            '매입이 매출보다 많으면 환급받을 수도 있어요.',
      ),
      TaxEvent(
        title: '부가세 2기 예정고지',
        subtitle: '7.1~9.30 납부',
        date: DateTime(year, 10, 25),
        color: AppColors.primary,
        description:
            '국세청이 직전 반기(1기) 확정 납부세액의 50%를 고지서로 보내줘요.\n\n'
            '직접 신고할 필요 없이 고지된 금액만 납부하면 돼요. '
            '다음 해 1월 확정신고 때 이미 낸 금액은 차감됩니다.',
      ),
      TaxEvent(
        title: '부가세 2기 확정 신고',
        subtitle: '7.1~12.31 신고·납부',
        date: DateTime(year + 1, 1, 25),
        color: AppColors.primary,
        description:
            '7월~12월까지의 실제 매출·매입 자료를 직접 홈택스에 신고해요.\n\n'
            '10월에 낸 예정고지 세액은 차감되므로, 나머지 차액만 납부하면 됩니다. '
            '매입이 매출보다 많으면 환급받을 수도 있어요.',
      ),
    ];
  }

  List<TaxEvent> _getEventsForMonth(DateTime month) {
    return _getAllEvents()
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();
  }

  List<TaxEvent> _getUpcomingEvents() {
    final now = DateTime.now();
    final events = _getAllEvents()
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList();
    events.sort((a, b) => a.date.compareTo(b.date));
    return events.take(3).toList();
  }

  Set<int> _getEventDays(DateTime month) {
    return _getEventsForMonth(month).map((e) => e.date.day).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return NotionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('세금 캘린더', style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Mini calendar
          _buildMiniCalendar(),

          const SizedBox(height: 16),

          // Divider
          const Divider(color: AppColors.divider, height: 1),

          const SizedBox(height: 16),

          // Upcoming timeline
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final eventDays = _getEventDays(_displayedMonth);
    final eventsThisMonth = _getEventsForMonth(_displayedMonth);
    final eventsByDay = <int, TaxEvent>{};
    for (final e in eventsThisMonth) {
      eventsByDay[e.date.day] = e;
    }
    final now = DateTime.now();

    // Month navigation
    final monthHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month - 1,
                  1,
                );
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        Text(
          '${_displayedMonth.year}.${_displayedMonth.month.toString().padLeft(2, '0')}',
          style: AppTypography.textTheme.titleSmall,
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _displayedMonth = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month + 1,
                  1,
                );
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // Weekday headers
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayRow = Row(
      children: weekdays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: AppTypography.caption.copyWith(
                    color: d == '일'
                        ? AppColors.danger
                        : d == '토'
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );

    // Calendar grid
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday =
          now.year == _displayedMonth.year &&
          now.month == _displayedMonth.month &&
          now.day == day;
      final hasEvent = eventDays.contains(day);

      final dayCell = Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary
                : hasEvent
                ? AppColors.primaryLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday || hasEvent
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isToday
                        ? Colors.white
                        : hasEvent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                if (hasEvent && !isToday)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      if (hasEvent && eventsByDay.containsKey(day)) {
        cells.add(
          GestureDetector(
            onTap: () => _showEventDetail(context, eventsByDay[day]!),
            child: dayCell,
          ),
        );
      } else {
        cells.add(dayCell);
      }
    }

    return Column(
      children: [
        monthHeader,
        const SizedBox(height: 12),
        weekdayRow,
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final events = _getUpcomingEvents();

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('올해 남은 세금 일정이 없어요', style: AppTypography.caption),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다가오는 일정',
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...events.asMap().entries.map((entry) {
          final i = entry.key;
          final event = entry.value;
          final isLast = i == events.length - 1;
          final dday = Formatters.formatDday(event.date);
          final isUrgent = event.date.difference(DateTime.now()).inDays <= 14;

          return GestureDetector(
            onTap: event.description != null
                ? () => _showEventDetail(context, event)
                : null,
            behavior: HitTestBehavior.opaque,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot + line
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: AppColors.borderLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: AppTypography.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${event.date.month}/${event.date.day} · ${event.subtitle}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? AppColors.dangerLight
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dday,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isUrgent
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showEventDetail(BuildContext context, TaxEvent event) {
    final dateStr =
        '${event.date.year}.${event.date.month.toString().padLeft(2, '0')}.${event.date.day.toString().padLeft(2, '0')}';
    final dday = Formatters.formatDday(event.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 타이틀 + D-day 배지
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.title,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dday,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 날짜 · 기간
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                '$dateStr · ${event.subtitle}',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 16),
            // 설명
            Text(
              event.description!,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
