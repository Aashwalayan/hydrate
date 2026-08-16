import 'package:flutter/material.dart';

import '../../services/hydration_service.dart';
import '../../widgets/hydration_progress.dart';

class HydrationGoalScreen extends StatefulWidget {
  const HydrationGoalScreen({super.key});

  @override
  State<HydrationGoalScreen> createState() => _HydrationGoalScreenState();
}

class _HydrationGoalScreenState extends State<HydrationGoalScreen> {
  final HydrationService _hydrationService = HydrationService();
  final TextEditingController _customGoalController = TextEditingController();

  DailyHydration? _today;

  int? _selectedGoal;
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<int> _presetGoals = [1500, 2000, 2500, 3000, 3500];

  @override
  void initState() {
    super.initState();
    _loadCachedHydration();
  }

  Future<void> _loadCachedHydration() async {
    final cachedToday = await _hydrationService.getCachedToday();

    if (!mounted) return;

    setState(() {
      _today = cachedToday;
      _selectedGoal = cachedToday?.goalMl;
      _isLoading = false;
    });

    if (cachedToday != null) {
      _customGoalController.text = cachedToday.goalMl.toString();
    }
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  void _selectGoal(int goalMl) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedGoal = goalMl;
      _customGoalController.text = goalMl.toString();
    });
  }

  void _onCustomGoalChanged(String value) {
    final goal = int.tryParse(value);

    setState(() {
      _selectedGoal = goal;
    });
  }

  bool get _hasChanged {
    if (_today == null || _selectedGoal == null) return false;

    return _selectedGoal != _today!.goalMl;
  }

  bool get _isValidGoal {
    final goal = _selectedGoal;

    return goal != null && goal >= 500 && goal <= 10000;
  }

  Future<void> _updateGoal() async {
    if (!_hasChanged || !_isValidGoal || _isSaving) return;

    final newGoal = _selectedGoal!;

    setState(() {
      _isSaving = true;
    });

    final result = await _hydrationService.updateGoal(newGoal);

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      return;
    }

    final updatedToday = await _hydrationService.getCachedToday();

    if (!mounted) return;

    setState(() {
      _today = updatedToday;
      _selectedGoal = newGoal;
      _isSaving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hydration goal updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hydration Goal'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _today == null
          ? _EmptyGoalState(onRetry: _loadCachedHydration)
          : SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _CurrentGoalCard(goalMl: _today!.goalMl),

                        const SizedBox(height: 32),

                        HydrationProgress(
                          currentIntake: _today!.intakeMl,
                          dailyGoal: _today!.goalMl,
                          isLoading: false,
                        ),

                        const SizedBox(height: 36),

                        Text(
                          'CHANGE GOAL',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _PresetGoalSelector(
                          goals: _presetGoals,
                          selectedGoal: _selectedGoal,
                          onSelected: _selectGoal,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Custom amount',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        _CustomGoalField(
                          controller: _customGoalController,
                          onChanged: _onCustomGoalChanged,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Choose a goal between 500 ml and 10,000 ml.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _hasChanged && _isValidGoal && !_isSaving
                                ? _updateGoal
                                : null,
                            child: _isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Text('Update Goal'),
                          ),
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

class _CurrentGoalCard extends StatelessWidget {
  const _CurrentGoalCard({required this.goalMl});

  final int goalMl;

  String get _liters {
    final liters = goalMl / 1000;

    if (liters == liters.roundToDouble()) {
      return '${liters.toInt()}';
    }

    return liters.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_rounded,
              color: colorScheme.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current goal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_liters L / day',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetGoalSelector extends StatelessWidget {
  const _PresetGoalSelector({
    required this.goals,
    required this.selectedGoal,
    required this.onSelected,
  });

  final List<int> goals;
  final int? selectedGoal;
  final ValueChanged<int> onSelected;

  String _format(int ml) {
    final liters = ml / 1000;

    if (liters == liters.roundToDouble()) {
      return '${liters.toInt()} L';
    }

    return '${liters.toStringAsFixed(1)} L';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: goals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final goal = goals[index];
          final selected = selectedGoal == goal;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(goal),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.07),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _format(goal),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomGoalField extends StatelessWidget {
  const _CustomGoalField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Enter amount',
        suffixText: 'ml',
        prefixIcon: Icon(
          Icons.water_drop_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _EmptyGoalState extends StatelessWidget {
  const _EmptyGoalState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Hydration data unavailable',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved hydration data could not be found.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
