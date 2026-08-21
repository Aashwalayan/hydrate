import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/hydration_service.dart';

/// Production-quality Hydration History Screen featuring:
/// - GitHub / LeetCode style 52-week calendar heatmap
/// - Period selector (Weekly / Monthly / Yearly)
/// - Weekly, Monthly, and Yearly BarCharts (using fl_chart)
/// - Accurate data calculations (missing dates = 0 hydration)
/// - Dynamic physical comparison "Did You Know?" fact rotator
/// - Day detail bottom sheet inspection
/// - Full Material 3 theming with Dark / Light mode support
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum HistoryPeriod { weekly, monthly, yearly }

class _HistoryScreenState extends State<HistoryScreen> {
  final HydrationService _hydrationService = HydrationService();
  final ScrollController _heatmapScrollController = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, DailyHydration> _historyMap = {};
  List<DailyHydration> _rawHistory = [];

  HistoryPeriod _selectedPeriod = HistoryPeriod.weekly;
  int _funFactIndex = 0;

  // Navigation dates for analytics
  late DateTime _selectedMonthDate;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthDate = DateTime(now.year, now.month, 1);
    _selectedYear = now.year;

    _loadHistory();
  }

  @override
  void dispose() {
    _heatmapScrollController.dispose();
    super.dispose();
  }

  bool _isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await _hydrationService.getHistory();

      final map = <String, DailyHydration>{};
      for (final day in history) {
        map[day.date] = day;
      }

      if (!mounted) return;

      setState(() {
        _rawHistory = history;
        _historyMap = map;
        _isLoading = false;
      });

      // Scroll heatmap to the latest days after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_heatmapScrollController.hasClients) {
          _heatmapScrollController.jumpTo(
            _heatmapScrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Color _heatmapColor(BuildContext context, int level) {
    final colorScheme = Theme.of(context).colorScheme;

    if (level <= 0) {
      return colorScheme.onSurface.withValues(alpha: 0.06);
    }

    switch (level) {
      case 1:
        return colorScheme.primary.withValues(alpha: 0.30);
      case 2:
        return colorScheme.primary.withValues(alpha: 0.48);
      case 3:
        return colorScheme.primary.withValues(alpha: 0.66);
      case 4:
        return colorScheme.primary.withValues(alpha: 0.84);
      case 5:
      default:
        return colorScheme.primary;
    }
  }

  int _calculateTrackedDaysCount() {
    return _rawHistory.where((d) => d.intakeMl > 0).length;
  }

  void _showDayDetailsSheet(DateTime date, DailyHydration? data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayDetailsBottomSheet(date: date, data: data),
    );
  }

  void _nextFunFact() {
    setState(() {
      _funFactIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(theme, colorScheme)),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const _HistoryLoadingView();
    }

    if (_errorMessage != null) {
      return _HistoryErrorView(message: _errorMessage!, onRetry: _loadHistory);
    }

    if (_rawHistory.isEmpty) {
      return _HistoryEmptyView(onRefresh: _loadHistory);
    }

    final trackedDays = _calculateTrackedDaysCount();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // 1. GitHub-style Hydration Heatmap
          // -------------------------------------------------------------
          Text(
            'Hydration consistency',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your hydration activity over the past year',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),

          _buildHeatmapCard(theme, colorScheme, trackedDays),

          const SizedBox(height: 28),

          // -------------------------------------------------------------
          // 2. Period Selector (Weekly | Monthly | Yearly)
          // -------------------------------------------------------------
          _buildPeriodSelector(colorScheme, theme),

          const SizedBox(height: 28),

          // -------------------------------------------------------------
          // 3, 4, 5. Analytics Sections with Animated Switcher
          // -------------------------------------------------------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _buildSelectedAnalytics(theme, colorScheme),
          ),

          const SizedBox(height: 32),

          // -------------------------------------------------------------
          // 6. Fun facts comparison section
          // -------------------------------------------------------------
          _buildFunFactsSection(theme, colorScheme),
        ],
      ),
    );
  }

  // =========================================================================
  // Heatmap Card
  // =========================================================================
  Widget _buildHeatmapCard(
    ThemeData theme,
    ColorScheme colorScheme,
    int trackedDays,
  ) {
    // Generate 52 weeks of dates ending at current week
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find upcoming Sunday or current Sunday to complete the week
    final daysUntilSunday = (7 - today.weekday) % 7;
    final lastCalendarDay = today.add(Duration(days: daysUntilSunday));

    const totalWeeks = 52;
    const totalDays = totalWeeks * 7;
    final firstCalendarDay = lastCalendarDay.subtract(
      const Duration(days: totalDays - 1),
    );

    // Build weeks matrix: 52 columns x 7 rows (Monday=0 to Sunday=6)
    final weeks = <List<DateTime>>[];
    for (int w = 0; w < totalWeeks; w++) {
      final weekDays = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        final date = firstCalendarDay.add(Duration(days: (w * 7) + d));
        weekDays.add(date);
      }
      weeks.add(weekDays);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap grid with horizontal scrolling
          SizedBox(
            height: 156,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day of week labels (M, W, F)
                Padding(
                  padding: const EdgeInsets.only(top: 24, right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DayLabel('M', theme, colorScheme),
                      _DayLabel('W', theme, colorScheme),
                      _DayLabel('F', theme, colorScheme),
                    ],
                  ),
                ),

                // Scrollable heatmap grid with month headers
                Expanded(
                  child: SingleChildScrollView(
                    controller: _heatmapScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month labels row
                        SizedBox(
                          height: 18,
                          child: Row(
                            children: [
                              for (int w = 0; w < weeks.length; w++)
                                SizedBox(
                                  width: 16,
                                  child: _getMonthLabelForWeek(
                                    weeks,
                                    w,
                                    theme,
                                    colorScheme,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 7 rows of days
                        for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                for (int w = 0; w < weeks.length; w++) ...[
                                  _buildHeatmapSquare(
                                    weeks[w][dayIndex],
                                    today,
                                    colorScheme,
                                  ),
                                  const SizedBox(width: 3),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend & Tracked count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$trackedDays ${trackedDays == 1 ? 'day' : 'days'} tracked',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Less -> More Legend
              Row(
                children: [
                  Text(
                    'Less',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (int level = 0; level <= 5; level++)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _heatmapColor(context, level),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _getMonthLabelForWeek(
    List<List<DateTime>> weeks,
    int weekIndex,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final firstDayInWeek = weeks[weekIndex].first;
    final isFirstWeekOfMonth = firstDayInWeek.day <= 7;

    if (isFirstWeekOfMonth) {
      final monthName = _shortMonthName(firstDayInWeek.month);
      return OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: 40,
        child: Text(
          monthName,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeatmapSquare(
    DateTime date,
    DateTime today,
    ColorScheme colorScheme,
  ) {
    final isFuture = date.isAfter(today);
    if (isFuture) {
      return Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final key = _formatDateKey(date);
    final dayData = _historyMap[key];
    final level = dayData?.level ?? 0;
    final color = _heatmapColor(context, level);

    return InkWell(
      onTap: () => _showDayDetailsSheet(date, dayData),
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: date == today
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.04),
            width: date == today ? 1.2 : 0.5,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Period Selector
  // =========================================================================
  Widget _buildPeriodSelector(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PeriodTabButton(
            title: 'Weekly',
            isSelected: _selectedPeriod == HistoryPeriod.weekly,
            onTap: () => setState(() => _selectedPeriod = HistoryPeriod.weekly),
          ),
          _PeriodTabButton(
            title: 'Monthly',
            isSelected: _selectedPeriod == HistoryPeriod.monthly,
            onTap: () =>
                setState(() => _selectedPeriod = HistoryPeriod.monthly),
          ),
          _PeriodTabButton(
            title: 'Yearly',
            isSelected: _selectedPeriod == HistoryPeriod.yearly,
            onTap: () => setState(() => _selectedPeriod = HistoryPeriod.yearly),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAnalytics(ThemeData theme, ColorScheme colorScheme) {
    switch (_selectedPeriod) {
      case HistoryPeriod.weekly:
        return _buildWeeklyAnalytics(theme, colorScheme);
      case HistoryPeriod.monthly:
        return _buildMonthlyAnalytics(theme, colorScheme);
      case HistoryPeriod.yearly:
        return _buildYearlyAnalytics(theme, colorScheme);
    }
  }

  // =========================================================================
  // 3. Weekly Analytics
  // =========================================================================
  Widget _buildWeeklyAnalytics(ThemeData theme, ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find Monday of the current week (weekday 1 = Monday)
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dailyIntakes = <int>[];
    final completionPercents = <int>[];

    for (final day in weekDays) {
      final key = _formatDateKey(day);
      final entry = _historyMap[key];
      dailyIntakes.add(entry?.intakeMl ?? 0);
      completionPercents.add(entry?.completionPercent ?? 0);
    }

    // Weekly statistics
    final totalWeeklyMl = dailyIntakes.reduce((a, b) => a + b);
    final daysPassed = math.min(7, today.weekday);
    final averageDailyMl = daysPassed > 0
        ? (totalWeeklyMl / daysPassed).round()
        : 0;
    final bestDayMl = dailyIntakes.reduce(math.max);
    final goalDaysCount = completionPercents.where((p) => p >= 100).length;

    // Streak calculation (current consecutive active days up to today)
    final currentStreak = _calculateStreak(today);

    return Column(
      key: const ValueKey('weekly_analytics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly hydration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'This Week',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bar Chart
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 120,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = weekDays[group.x.toInt()];
                    final intake = dailyIntakes[group.x.toInt()];
                    final percent = completionPercents[group.x.toInt()];
                    return BarTooltipItem(
                      '${_weekdayName(day.weekday)}\n$intake ml ($percent%)',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 50,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      const labels = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      final idx = val.toInt();
                      if (idx < 0 || idx >= labels.length)
                        return const SizedBox.shrink();
                      final isCurrent = idx == (today.weekday - 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            color: isCurrent
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.55),
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colorScheme.onSurface.withValues(
                      alpha: value == 100 ? 0.2 : 0.05,
                    ),
                    strokeWidth: value == 100 ? 1.2 : 1,
                    dashArray: value == 100 ? [4, 4] : null,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < 7; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: math.min(120.0, completionPercents[i].toDouble()),
                        color: completionPercents[i] >= 100
                            ? colorScheme.primary
                            : completionPercents[i] > 0
                            ? colorScheme.primary.withValues(alpha: 0.65)
                            : colorScheme.onSurface.withValues(alpha: 0.08),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Stat Cards
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Average / day',
                value: _formatLitres(averageDailyMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Best day',
                value: _formatLitres(bestDayMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(title: 'Goal days', value: '$goalDaysCount / 7'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Streak',
                value: '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 4. Monthly Analytics
  // =========================================================================
  Widget _buildMonthlyAnalytics(ThemeData theme, ColorScheme colorScheme) {
    final now = DateTime.now();
    final year = _selectedMonthDate.year;
    final month = _selectedMonthDate.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    final dailyIntakes = <int>[];
    final completionPercents = <int>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final key = _formatDateKey(date);
      final entry = _historyMap[key];
      dailyIntakes.add(entry?.intakeMl ?? 0);
      completionPercents.add(entry?.completionPercent ?? 0);
    }

    final totalMonthlyMl = dailyIntakes.reduce((a, b) => a + b);
    final daysToAverage = (year == now.year && month == now.month)
        ? math.max(1, now.day)
        : daysInMonth;
    final avgDailyMl = (totalMonthlyMl / daysToAverage).round();
    final bestDayMl = dailyIntakes.reduce(math.max);
    final goalDaysCount = completionPercents.where((p) => p >= 100).length;
    final avgCompletion = daysToAverage > 0
        ? (completionPercents.take(daysToAverage).reduce((a, b) => a + b) /
                  daysToAverage)
              .round()
        : 0;

    final isCurrentMonth = (year == now.year && month == now.month);

    return Column(
      key: const ValueKey('monthly_analytics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly hydration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            // Month navigation
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _selectedMonthDate = DateTime(year, month - 1, 1);
                    });
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '${month.toString().padLeft(2, '0')} / $year',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: isCurrentMonth
                      ? null
                      : () {
                          setState(() {
                            _selectedMonthDate = DateTime(year, month + 1, 1);
                          });
                        },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Monthly Bar Chart
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 120,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayNum = group.x.toInt() + 1;
                    final intake = dailyIntakes[group.x.toInt()];
                    final pct = completionPercents[group.x.toInt()];
                    return BarTooltipItem(
                      'Day $dayNum: $intake ml ($pct%)',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 50,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final dayNum = val.toInt() + 1;
                      if (dayNum == 1 ||
                          dayNum % 5 == 0 ||
                          dayNum == daysInMonth) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colorScheme.onSurface.withValues(
                      alpha: value == 100 ? 0.2 : 0.05,
                    ),
                    strokeWidth: 1,
                    dashArray: value == 100 ? [4, 4] : null,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < daysInMonth; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: math.min(120.0, completionPercents[i].toDouble()),
                        color: completionPercents[i] >= 100
                            ? colorScheme.primary
                            : completionPercents[i] > 0
                            ? colorScheme.primary.withValues(alpha: 0.65)
                            : colorScheme.onSurface.withValues(alpha: 0.08),
                        width: (math.max(4.0, (260 / daysInMonth) - 2)),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Monthly Stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total intake',
                value: _formatLitres(totalMonthlyMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Avg / day',
                value: _formatLitres(avgDailyMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Avg completion',
                value: '$avgCompletion%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Best day',
                value: _formatLitres(bestDayMl),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 5. Yearly Analytics
  // =========================================================================
  Widget _buildYearlyAnalytics(ThemeData theme, ColorScheme colorScheme) {
    final now = DateTime.now();
    final year = _selectedYear;

    final monthlyTotalMl = List<int>.filled(12, 0);
    final monthlyAvgPercent = List<int>.filled(12, 0);
    int totalYearlyMl = 0;
    int totalGoalDays = 0;

    for (int m = 1; m <= 12; m++) {
      final daysInM = DateUtils.getDaysInMonth(year, m);
      int monthMl = 0;
      int monthPercentSum = 0;

      for (int d = 1; d <= daysInM; d++) {
        final date = DateTime(year, m, d);
        final key = _formatDateKey(date);
        final entry = _historyMap[key];
        final intake = entry?.intakeMl ?? 0;
        final pct = entry?.completionPercent ?? 0;

        monthMl += intake;
        monthPercentSum += pct;

        if (pct >= 100) {
          totalGoalDays++;
        }
      }

      monthlyTotalMl[m - 1] = monthMl;
      monthlyAvgPercent[m - 1] = (monthPercentSum / daysInM).round();
      totalYearlyMl += monthMl;
    }

    // Best month
    int bestMonthIndex = 0;
    int maxMonthMl = 0;
    for (int i = 0; i < 12; i++) {
      if (monthlyTotalMl[i] > maxMonthMl) {
        maxMonthMl = monthlyTotalMl[i];
        bestMonthIndex = i;
      }
    }

    final isCurrentYear = (year == now.year);
    final elapsedDaysInYear = isCurrentYear
        ? now.difference(DateTime(year, 1, 1)).inDays + 1
        : (_isLeapYear(year) ? 366 : 365);
    final avgDailyYearMl = elapsedDaysInYear > 0
        ? (totalYearlyMl / elapsedDaysInYear).round()
        : 0;
    final avgYearlyPercent =
        (monthlyAvgPercent
                    .take(isCurrentYear ? now.month : 12)
                    .reduce((a, b) => a + b) /
                (isCurrentYear ? now.month : 12))
            .round();

    return Column(
      key: const ValueKey('yearly_analytics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yearly hydration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '$year',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: isCurrentYear
                      ? null
                      : () {
                          setState(() => _selectedYear++);
                        },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Yearly 12-bar chart
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 120,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final m = group.x.toInt() + 1;
                    final totalL = (monthlyTotalMl[group.x.toInt()] / 1000)
                        .toStringAsFixed(1);
                    final pct = monthlyAvgPercent[group.x.toInt()];
                    return BarTooltipItem(
                      '${_fullMonthName(m)}\n$totalL L (${pct}% avg)',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 50,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      const labels = [
                        'J',
                        'F',
                        'M',
                        'A',
                        'M',
                        'J',
                        'J',
                        'A',
                        'S',
                        'O',
                        'N',
                        'D',
                      ];
                      final idx = val.toInt();
                      if (idx < 0 || idx >= labels.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colorScheme.onSurface.withValues(
                      alpha: value == 100 ? 0.2 : 0.05,
                    ),
                    strokeWidth: 1,
                    dashArray: value == 100 ? [4, 4] : null,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < 12; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: math.min(120.0, monthlyAvgPercent[i].toDouble()),
                        color: monthlyAvgPercent[i] >= 100
                            ? colorScheme.primary
                            : monthlyAvgPercent[i] > 0
                            ? colorScheme.primary.withValues(alpha: 0.65)
                            : colorScheme.onSurface.withValues(alpha: 0.08),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Yearly stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total intake',
                value: _formatLitres(totalYearlyMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Avg / day',
                value: _formatLitres(avgDailyYearMl),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Best month',
                value: maxMonthMl > 0
                    ? _shortMonthName(bestMonthIndex + 1)
                    : '-',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(title: 'Goal days', value: '$totalGoalDays'),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 6. Fun Facts Section (Dynamic physically sensible comparisons)
  // =========================================================================
  Widget _buildFunFactsSection(ThemeData theme, ColorScheme colorScheme) {
    final periodIntakeLitres = _calculatePeriodIntakeLitres();

    final facts = _generateFunFacts(periodIntakeLitres);
    final activeFact = facts[_funFactIndex % facts.length];

    final periodLabel = switch (_selectedPeriod) {
      HistoryPeriod.weekly => 'this week',
      HistoryPeriod.monthly => 'this month',
      HistoryPeriod.yearly => 'this year',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DID YOU KNOW?',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${periodIntakeLitres.toStringAsFixed(1)} Litres $periodLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  activeFact,
                  key: ValueKey('fact_${_funFactIndex % facts.length}'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: _nextFunFact,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Another fact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculatePeriodIntakeLitres() {
    final now = DateTime.now();
    int totalMl = 0;

    switch (_selectedPeriod) {
      case HistoryPeriod.weekly:
        final today = DateTime(now.year, now.month, now.day);
        final monday = today.subtract(Duration(days: today.weekday - 1));
        for (int i = 0; i < 7; i++) {
          final day = monday.add(Duration(days: i));
          totalMl += _historyMap[_formatDateKey(day)]?.intakeMl ?? 0;
        }
        break;

      case HistoryPeriod.monthly:
        final daysInM = DateUtils.getDaysInMonth(
          _selectedMonthDate.year,
          _selectedMonthDate.month,
        );
        for (int d = 1; d <= daysInM; d++) {
          final date = DateTime(
            _selectedMonthDate.year,
            _selectedMonthDate.month,
            d,
          );
          totalMl += _historyMap[_formatDateKey(date)]?.intakeMl ?? 0;
        }
        break;

      case HistoryPeriod.yearly:
        for (int m = 1; m <= 12; m++) {
          final daysInM = DateUtils.getDaysInMonth(_selectedYear, m);
          for (int d = 1; d <= daysInM; d++) {
            final date = DateTime(_selectedYear, m, d);
            totalMl += _historyMap[_formatDateKey(date)]?.intakeMl ?? 0;
          }
        }
        break;
    }

    if (totalMl == 0 && _rawHistory.isNotEmpty) {
      // Fallback to all-time total if current selected period has 0 intake
      totalMl = _rawHistory.fold(0, (sum, d) => sum + d.intakeMl);
    }

    return totalMl / 1000.0;
  }

  List<String> _generateFunFacts(double litres) {
    if (litres <= 0) {
      return [
        'Log your first glass of water to unlock fascinating physical comparisons!',
        'Every sip of water helps your brain maintain peak focus and energy.',
      ];
    }

    // Standard physical constants:
    // 1 standard bathtub = ~150 Liters
    // 1 five-minute shower = ~47.5 Liters (at 9.5 L/min standard flow)
    // 1 basketball volume = ~7.1 Liters
    // 1 ice cube = ~28 ml (~35 ice cubes per Liter)
    // 1 standard fuel efficiency = 7.0 L / 100 km (~14.3 km per Liter of petrol)
    // 1 standard 500 ml bottle = 0.5 Liters
    // 1 coffee mug = 250 ml (0.25 Liters)
    // 1 household bucket = 10 Liters

    final bathtubs = (litres / 150.0).toStringAsFixed(2);
    final bottles = (litres / 0.5).round();
    final showers = (litres / 47.5).toStringAsFixed(1);
    final basketballs = (litres / 7.1).toStringAsFixed(1);
    final iceCubes = (litres * 35).round();
    final carKm = ((litres / 7.0) * 100).round();
    final coffeeMugs = (litres / 0.25).round();
    final buckets = (litres / 10.0).toStringAsFixed(1);

    return [
      "That's roughly $bathtubs bathtubs of water.",
      "That's equal to $bottles standard 500 ml water bottles.",
      "That would fill approximately $basketballs regulation basketballs worth of volume.",
      "That is equivalent to about $showers standard five-minute showers.",
      "That's approximately $iceCubes standard ice cubes.",
      "If this volume were petrol, it could theoretically fuel a car for ~$carKm km.",
      "That would fill about $coffeeMugs medium coffee mugs to the brim.",
      "That is about $buckets large household buckets of water.",
    ];
  }

  // =========================================================================
  // Helpers
  // =========================================================================
  int _calculateStreak(DateTime today) {
    int streak = 0;
    var checkDate = today;

    // If today has 0 intake, check if streak ended yesterday or continues
    final todayEntry = _historyMap[_formatDateKey(today)];
    if (todayEntry == null || todayEntry.intakeMl == 0) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _formatDateKey(checkDate);
      final day = _historyMap[key];
      if (day != null && day.intakeMl > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatLitres(int ml) {
    if (ml <= 0) return '0 L';
    if (ml >= 1000) {
      final l = ml / 1000.0;
      return '${l.toStringAsFixed(l >= 10 ? 1 : 2)} L';
    }
    return '$ml ml';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _fullMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

// ===========================================================================
// Sub-Widgets & Sheets
// ===========================================================================

class _PeriodTabButton extends StatelessWidget {
  const _PeriodTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.text, this.theme, this.colorScheme);

  final String text;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDetailsBottomSheet extends StatelessWidget {
  const _DayDetailsBottomSheet({required this.date, required this.data});

  final DateTime date;
  final DailyHydration? data;

  String _formatFullDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final intake = data?.intakeMl ?? 0;
    final goal = data?.goalMl ?? 2000;
    final percent = data?.completionPercent ?? 0;
    final entries = data?.entries ?? const [];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Text(
            _formatFullDate(date),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Overview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intake > 0 ? '$intake / $goal ml' : 'No water logged',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intake > 0
                          ? '$percent% completed • Level ${data?.level ?? 0}'
                          : '0% completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                Icon(
                  intake > 0
                      ? Icons.water_drop_rounded
                      : Icons.water_drop_outlined,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Entries List
          Text(
            'Activity breakdown (${entries.length} ${entries.length == 1 ? 'entry' : 'entries'})',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No water logs recorded on this date.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (ctx, idx) {
                  final entry = entries[idx];
                  return Row(
                    children: [
                      Icon(
                        Icons.local_drink_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${entry.amountMl} ml',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        TimeOfDay.fromDateTime(entry.timestamp).format(ctx),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryLoadingView extends StatelessWidget {
  const _HistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 32),
          Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        ],
      ),
    );
  }
}

class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Unable to load history',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyView extends StatelessWidget {
  const _HistoryEmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Your hydration story starts here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your first glass of water and your history will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check for updates'),
            ),
          ],
        ),
      ),
    );
  }
}
