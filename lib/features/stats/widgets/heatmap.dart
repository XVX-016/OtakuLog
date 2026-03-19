import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:intl/intl.dart';

class ActivityHeatmap extends ConsumerStatefulWidget {
  const ActivityHeatmap({super.key});

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  static const double _cellSize = 28;
  static const double _gap = 5;

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(allSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Text(
            'Log your first session to build activity.',
            style: TextStyle(color: AppTheme.secondaryText),
          );
        }

        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final earliestSession = sessions
            .map((session) => session.startTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final earliestMonth = DateTime(
          earliestSession.year,
          earliestSession.month,
        );
        final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        final visibleEnd = _isSameMonth(_selectedMonth, currentMonth)
            ? DateTime(now.year, now.month, now.day)
            : monthEnd;
        final startMonday = monthStart.subtract(
          Duration(days: monthStart.weekday - DateTime.monday),
        );
        final totalDays = visibleEnd.difference(startMonday).inDays + 1;
        final totalWeeks = (totalDays / 7).ceil();
        final minutesByDay = _dailyMinutes(sessions);
        final canGoBack = !_isSameMonth(_selectedMonth, earliestMonth);
        final canGoNext = !_isSameMonth(_selectedMonth, currentMonth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: canGoBack
                      ? () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: canGoBack
                        ? AppTheme.primaryText
                        : AppTheme.secondaryText.withOpacity(0.35),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(monthStart),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canGoNext
                      ? () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: canGoNext
                        ? AppTheme.primaryText
                        : AppTheme.secondaryText.withOpacity(0.35),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth - 32
                    : (totalWeeks * (_cellSize + _gap)).toDouble();
                final fittedColumns = (availableWidth / (_cellSize + _gap))
                    .floor()
                    .clamp(1, 1000);
                final displayWeeks =
                    fittedColumns > totalWeeks ? fittedColumns : totalWeeks;
                final extraColumns = displayWeeks - totalWeeks;
                final leadingEmptyColumns = (extraColumns / 2).floor();
                final gridWidth = displayWeeks * _cellSize +
                    ((displayWeeks - 1).clamp(0, 1000) * _gap);

                return Center(
                  child: SizedBox(
                    width: gridWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(displayWeeks, (weekIndex) {
                        final monthWeekIndex = weekIndex - leadingEmptyColumns;
                        final fillerColumn =
                            monthWeekIndex < 0 || monthWeekIndex >= totalWeeks;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(7, (rowIndex) {
                            if (fillerColumn) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: rowIndex == 6 ? 0 : _gap,
                                ),
                                child: const SizedBox(
                                  width: _cellSize,
                                  height: _cellSize,
                                ),
                              );
                            }

                            final day = startMonday.add(
                              Duration(days: monthWeekIndex * 7 + rowIndex),
                            );
                            final normalizedDay = DateTime(
                              day.year,
                              day.month,
                              day.day,
                            );
                            final isHidden = normalizedDay.isBefore(monthStart) ||
                                normalizedDay.isAfter(visibleEnd);
                            final minutes =
                                isHidden ? 0 : (minutesByDay[normalizedDay] ?? 0);
                            final isToday = _isSameDay(normalizedDay, now);

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: rowIndex == 6 ? 0 : _gap,
                              ),
                              child: isHidden
                                  ? const SizedBox(
                                      width: _cellSize,
                                      height: _cellSize,
                                    )
                                  : Tooltip(
                                      message:
                                          '${DateFormat('MMM d').format(normalizedDay)} · $minutes min',
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: Container(
                                        width: _cellSize,
                                        height: _cellSize,
                                        decoration: BoxDecoration(
                                          color: _heatColor(minutes),
                                          borderRadius: BorderRadius.circular(3),
                                          border: isToday
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      ),
      error: (_, __) => const Text(
        'Activity unavailable right now.',
        style: TextStyle(color: AppTheme.secondaryText),
      ),
    );
  }

  Map<DateTime, int> _dailyMinutes(List<UserSessionEntity> sessions) {
    final minutesByDay = <DateTime, int>{};
    for (final session in sessions) {
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      minutesByDay.update(
        day,
        (value) => value + session.totalMinutes,
        ifAbsent: () => session.totalMinutes,
      );
    }
    return minutesByDay;
  }

  Color _heatColor(int minutes) {
    if (minutes == 0) return const Color(0xFF1E1E22);
    if (minutes <= 30) return const Color(0xFF6A2030);
    if (minutes <= 60) return const Color(0xFFA83040);
    if (minutes <= 120) return const Color(0xFFD84050);
    return const Color(0xFFE8354A);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}
