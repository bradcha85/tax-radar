import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'notion_card.dart';

class TaxEvent {
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;

  const TaxEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
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
      ),
      TaxEvent(
        title: '종합소득세 신고·납부',
        subtitle: '$year년 귀속',
        date: DateTime(year, 5, 31),
        color: AppColors.notionPurple,
      ),
      TaxEvent(
        title: '부가세 1기 확정 신고',
        subtitle: '1.1~6.30 신고·납부',
        date: DateTime(year, 7, 25),
        color: AppColors.primary,
      ),
      TaxEvent(
        title: '부가세 2기 예정고지',
        subtitle: '7.1~9.30 납부',
        date: DateTime(year, 10, 25),
        color: AppColors.primary,
      ),
      TaxEvent(
        title: '부가세 2기 확정 신고',
        subtitle: '7.1~12.31 신고·납부',
        date: DateTime(year + 1, 1, 25),
        color: AppColors.primary,
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
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '세금 캘린더',
                style: AppTypography.textTheme.titleMedium,
              ),
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
    final now = DateTime.now();

    // Month navigation
    final monthHeader = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth.year,
                _displayedMonth.month - 1,
                1,
              );
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
          ),
        ),
        Text(
          '${_displayedMonth.year}.${_displayedMonth.month.toString().padLeft(2, '0')}',
          style: AppTypography.textTheme.titleSmall,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _displayedMonth = DateTime(
                _displayedMonth.year,
                _displayedMonth.month + 1,
                1,
              );
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ),
        ),
      ],
    );

    // Weekday headers
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayRow = Row(
      children: weekdays
          .map((d) => Expanded(
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
              ))
          .toList(),
    );

    // Calendar grid
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = now.year == _displayedMonth.year &&
          now.month == _displayedMonth.month &&
          now.day == day;
      final hasEvent = eventDays.contains(day);

      cells.add(
        Center(
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
                      fontWeight: isToday || hasEvent ? FontWeight.w600 : FontWeight.w400,
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
        ),
      );
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
        child: Text(
          '올해 남은 세금 일정이 없어요',
          style: AppTypography.caption,
        ),
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

          return IntrinsicHeight(
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
                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
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
                            borderRadius: BorderRadius.circular(6),
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
          );
        }),
      ],
    );
  }
}
