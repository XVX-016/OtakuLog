import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:intl/intl.dart';

class ActivityHeatmap extends ConsumerStatefulWidget {
  const ActivityHeatmap({super.key});

  @override
  ConsumerState<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends ConsumerState<ActivityHeatmap> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final earliestAsync = ref.watch(earliestActivityDateProvider);
    final monthlyActivityAsync = ref.watch(monthlyActivityProvider(_selectedMonth));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        earliestAsync.when(
          data: (earliestDate) {
            final earliestMonth = earliestDate == null
                ? null
                : DateTime(earliestDate.year, earliestDate.month);
            final canGoBack = earliestMonth != null &&
                _selectedMonth.isAfter(earliestMonth);
            final canGoForward = _selectedMonth.isBefore(currentMonth);
            return Row(
              children: [
                IconButton(
                  onPressed: canGoBack
                      ? () => setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          })
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canGoForward
                      ? () => setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month + 1,
                            );
                          })
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MON', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('TUE', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('WED', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('THU', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('FRI', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('SAT', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text('SUN', style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        monthlyActivityAsync.when(
          data: (dailyMinutes) => _buildMonthGrid(context, dailyMinutes),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            'Could not load activity: $error',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(BuildContext context, Map<DateTime, int> dailyMinutes) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final leadingEmpty = firstDay.weekday - DateTime.monday;
    final totalCells = leadingEmpty + lastDay.day;
    final rowCount = (totalCells / 7).ceil();
    final days = List<DateTime?>.generate(rowCount * 7, (index) {
      final dayNumber = index - leadingEmpty + 1;
      if (dayNumber < 1 || dayNumber > lastDay.day) return null;
      return DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) return const SizedBox.shrink();
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final minutes = dailyMinutes[normalizedDay] ?? 0;
        final isToday = _isSameDay(normalizedDay, DateTime.now());
        return Tooltip(
          message: '${DateFormat('MMMM d').format(normalizedDay)} - $minutes min',
          child: Container(
            decoration: BoxDecoration(
              color: _cellColor(minutes),
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: Colors.white, width: 1.2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _cellColor(int minutes) {
    if (minutes <= 0) return AppTheme.elevated;
    if (minutes <= 30) return AppTheme.accent.withOpacity(0.30);
    if (minutes <= 60) return AppTheme.accent.withOpacity(0.55);
    if (minutes <= 120) return AppTheme.accent.withOpacity(0.75);
    return AppTheme.accent;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
