import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/hydration_service.dart';
import '../../widgets/hydration_progress.dart';
import '../../services/hydration_alarm_local_storage.dart';
import '../../services/hydration_reminder_utils.dart';

import 'alarm_screen.dart';

/// Primary dashboard for today's hydration.
///
/// Hydration data is loaded from the backend through HydrationService.
/// This screen does not own a PageView.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'there';
  String _greeting = 'Good evening';

  DailyHydration? _today;

  bool _isLoading = true;
  bool _isAddingWater = false;

  String? _errorMessage;

  // -------------------------------------------------------------------------
  // Reminder mock - will be replaced with real reminder logic next.
  // -------------------------------------------------------------------------

  final HydrationAlarmLocalStorage _alarmStorage = HydrationAlarmLocalStorage();

  HydrationAlarm? _alarm;
  NextHydrationReminder? _nextReminder;

  Timer? _countdownTimer;
  bool _justSkipped = false;

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _loadHydrationData();
    _loadAlarm();
  }

  Future<void> _loadAlarm() async {
    final alarm = await _alarmStorage.loadAlarm();

    if (!mounted) return;

    setState(() {
      _alarm = alarm;
    });

    _refreshReminder();

    _countdownTimer?.cancel();

    if (alarm != null && alarm.enabled) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _refreshReminder(),
      );
    }
  }

  void _refreshReminder() {
    final alarm = _alarm;

    if (alarm == null || !alarm.enabled) {
      if (mounted) {
        setState(() => _nextReminder = null);
      }
      return;
    }

    final reminder = calculateNextHydrationReminder(
      alarm: alarm,
      today: _today,
    );

    if (!mounted) return;

    setState(() {
      _nextReminder = reminder;
    });
  }

  void _handleSkip() {
    setState(() {
      _justSkipped = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _justSkipped = false;
        });
      }
    });
  }

  // -------------------------------------------------------------------------
  // User
  // -------------------------------------------------------------------------

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final name = await authService.getUserName();

    if (!mounted) return;

    setState(() {
      _userName = name ?? 'there';
      _greeting = _getGreeting();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Future<void> _loadHydrationData() async {
    final service = HydrationService();

    // 1. Load cached data immediately.
    final cachedToday = await service.getCachedToday();

    if (cachedToday != null && mounted) {
      setState(() {
        _today = cachedToday;
        _isLoading = false;
        _errorMessage = null;
      });
      _refreshReminder();
    }

    // 2. Fetch fresh data from the backend.
    try {
      final today = await service.getToday();

      if (!mounted) return;

      setState(() {
        _today = today;
        _isLoading = false;
        _errorMessage = null;
      });
      _refreshReminder();
    } catch (e) {
      debugPrint('Hydration loading error: $e');

      if (!mounted) return;

      // If we already have cached data, don't show an error.
      if (cachedToday != null) {
        return;
      }

      // No cache + backend unavailable.
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load hydration data.';
      });
    }
  }

  Future<void> _addWater(int amountMl) async {
    if (_isAddingWater) return;

    setState(() {
      _isAddingWater = true;
    });

    try {
      final service = HydrationService();

      final updatedToday = await service.addWater(amountMl);

      if (!mounted) return;

      setState(() {
        _today = updatedToday;
        _refreshReminder();
        _isAddingWater = false;
      });
    } catch (e) {
      debugPrint('Add water error: $e');

      if (!mounted) return;

      setState(() {
        _isAddingWater = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add water. Please try again.')),
      );
    }
  }

  Future<void> _openAddWaterSheet() async {
    if (_isAddingWater) return;

    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWaterSheet(),
    );

    if (amount == null) return;

    await _addWater(amount);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentIntake = _today?.intakeMl ?? 0;
    final dailyGoal = _today?.goalMl ?? 2500;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Greeting(userName: _userName, greeting: _greeting),

                  const SizedBox(height: 28),

                  if (_errorMessage != null)
                    _ErrorCard(
                      message: _errorMessage!,
                      onRetry: _loadHydrationData,
                    ),

                  HydrationProgress(
                    currentIntake: currentIntake,
                    dailyGoal: dailyGoal,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),

                  _AddWaterButton(
                    onTap: _openAddWaterSheet,
                    isLoading: _isAddingWater,
                  ),

                  const SizedBox(height: 24),

                  _NextReminderCard(
                    reminder: _nextReminder,
                    justSkipped: _justSkipped,
                    onSkip: _handleSkip,
                  ),

                  const SizedBox(height: 28),

                  _IntakeHistory(
                    entries: _today?.entries ?? const [],
                    isLoading: _isLoading,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.userName, required this.greeting});

  final String userName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's stay hydrated today",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _AddWaterButton extends StatelessWidget {
  const _AddWaterButton({required this.onTap, required this.isLoading});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.onPrimary.withValues(alpha: 0.18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: colorScheme.onPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Add Water',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AddWaterSheet extends StatefulWidget {
  const _AddWaterSheet();

  @override
  State<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends State<_AddWaterSheet> {
  static const List<int> _quickAmounts = [150, 250, 350, 500];

  int? _selectedAmount = 250;

  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '250');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _handleCustomAmountChanged(String value) {
    final amount = int.tryParse(value);

    setState(() {
      _selectedAmount = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'How much did you drink?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            // Quick presets
            Row(
              children: [
                for (int i = 0; i < _quickAmounts.length; i++) ...[
                  Expanded(
                    child: _AmountChip(
                      label: '${_quickAmounts[i]} ml',
                      selected: _selectedAmount == _quickAmounts[i],
                      onTap: () => _selectPreset(_quickAmounts[i]),
                    ),
                  ),
                  if (i != _quickAmounts.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Custom amount
            Text(
              'Custom amount',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _handleCustomAmountChanged,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                suffixText: 'ml',
                filled: true,
                fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                prefixIcon: Icon(
                  Icons.water_drop_outlined,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _selectedAmount == null || _selectedAmount! <= 0
                    ? null
                    : () {
                        Navigator.of(context).pop(_selectedAmount);
                      },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.14)
          : colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({
    required this.reminder,
    required this.justSkipped,
    required this.onSkip,
  });

  final NextHydrationReminder? reminder;
  final bool justSkipped;
  final VoidCallback onSkip;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatted = _formatDuration(reminder?.secondsRemaining ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXT REMINDER',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),

              AnimatedOpacity(
                opacity: justSkipped ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Skipped',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              formatted,
              key: ValueKey(formatted),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    reminder?.amountMl != null
                        ? 'Drink ${reminder!.amountMl} ml'
                        : 'Drink water',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntakeHistory extends StatelessWidget {
  const _IntakeHistory({required this.entries, required this.isLoading});

  final List<HydrationEntry> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's intake",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No water logged yet today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
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
                    TimeOfDay.fromDateTime(entry.timestamp).format(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
