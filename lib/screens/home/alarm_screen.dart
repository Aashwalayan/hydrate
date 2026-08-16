import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Whether an alarm's reminder times are evenly spaced between a start and
/// end time, or manually set one-by-one.
enum AlarmScheduleType { equalIntervals, custom }

/// Placeholder tone selection. No native ringtone access yet — this is a
/// frontend-only choice until real tone/ringtone integration is added.
enum AlarmTone { defaultTone, chime, droplet, bell, gentleWave, silent }

extension AlarmToneDisplay on AlarmTone {
  String get label {
    switch (this) {
      case AlarmTone.defaultTone:
        return 'Default';
      case AlarmTone.chime:
        return 'Chime';
      case AlarmTone.droplet:
        return 'Droplet';
      case AlarmTone.bell:
        return 'Bell';
      case AlarmTone.gentleWave:
        return 'Gentle Wave';
      case AlarmTone.silent:
        return 'Silent';
    }
  }

  IconData get icon {
    switch (this) {
      case AlarmTone.defaultTone:
        return Icons.notifications_outlined;
      case AlarmTone.chime:
        return Icons.music_note_outlined;
      case AlarmTone.droplet:
        return Icons.water_drop_outlined;
      case AlarmTone.bell:
        return Icons.notifications_active_outlined;
      case AlarmTone.gentleWave:
        return Icons.waves_outlined;
      case AlarmTone.silent:
        return Icons.volume_off_outlined;
    }
  }
}

/// Mock model for a single hydration reminder schedule.
///
/// Structured so a real notification-scheduling model can replace this
/// without touching the widgets that render it. [reminderTimes] is always
/// the source of truth for what actually fires — it's computed once (either
/// evenly spaced or manually picked) rather than left for a future
/// notification system to derive from [startTime]/[endTime].
class HydrationAlarm {
  const HydrationAlarm({
    required this.id,
    required this.label,
    required this.scheduleType,
    required this.reminderTimes,
    required this.enabled,
    this.startTime,
    this.endTime,
    this.intervalMinutes,
    this.tone = AlarmTone.defaultTone,
  });

  final String id;
  final String label;
  final AlarmScheduleType scheduleType;

  /// Sorted list of times this alarm will remind at. Always populated,
  /// regardless of [scheduleType].
  final List<TimeOfDay> reminderTimes;

  final bool enabled;

  /// Only meaningful for [AlarmScheduleType.equalIntervals] — kept so the
  /// editor can be reopened pre-filled with the original range.
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int? intervalMinutes;

  final AlarmTone tone;

  TimeOfDay get firstReminder => reminderTimes.first;
  TimeOfDay get lastReminder => reminderTimes.last;

  String scheduleSummary(BuildContext context) {
    if (scheduleType == AlarmScheduleType.equalIntervals &&
        intervalMinutes != null) {
      return 'Every $intervalMinutes minutes';
    }
    return 'Custom · ${reminderTimes.length} reminders';
  }

  HydrationAlarm copyWith({bool? enabled}) {
    return HydrationAlarm(
      id: id,
      label: label,
      scheduleType: scheduleType,
      reminderTimes: reminderTimes,
      enabled: enabled ?? this.enabled,
      startTime: startTime,
      endTime: endTime,
      intervalMinutes: intervalMinutes,
      tone: tone,
    );
  }
}

// ---------------------------------------------------------------------------
// Time helpers
// ---------------------------------------------------------------------------

int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay _fromMinutes(int minutes) {
  final wrapped = minutes % (24 * 60);
  return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
}

int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) =>
    _toMinutes(a).compareTo(_toMinutes(b));

/// Generates [count] evenly spaced times from [start] to [end] inclusive.
/// If [end] is earlier in the day than [start], the range is treated as
/// wrapping past midnight.
List<TimeOfDay> generateEqualIntervalTimes(
  TimeOfDay start,
  TimeOfDay end,
  int count,
) {
  if (count <= 1) return [start];

  final startMinutes = _toMinutes(start);
  var endMinutes = _toMinutes(end);
  if (endMinutes <= startMinutes) {
    endMinutes += 24 * 60;
  }

  final stepMinutes = (endMinutes - startMinutes) / (count - 1);

  return List.generate(
    count,
    (i) => _fromMinutes((startMinutes + (stepMinutes * i).round())),
  );
}

int equalIntervalStepMinutes(TimeOfDay start, TimeOfDay end, int count) {
  if (count <= 1) return 0;
  final startMinutes = _toMinutes(start);
  var endMinutes = _toMinutes(end);
  if (endMinutes <= startMinutes) endMinutes += 24 * 60;
  return ((endMinutes - startMinutes) / (count - 1)).round();
}

// ---------------------------------------------------------------------------
// Alarm screen
// ---------------------------------------------------------------------------

/// Alarm management screen — controls WHEN Hydrate reminds the user, as
/// opposed to [HomeScreen] which is about today's progress.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // --- Mock data. Replace with real state/providers later. -----------------
  // The first entry is always rendered as the "primary" card; everything
  // after it renders under "Additional alarms". This list is the single
  // source of truth, so add/edit/delete/toggle all just mutate it and the
  // cards below update accordingly.
  late final List<HydrationAlarm> _alarms = [
    HydrationAlarm(
      id: 'primary',
      label: 'Hydration reminders',
      scheduleType: AlarmScheduleType.equalIntervals,
      reminderTimes: generateEqualIntervalTimes(
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 22, minute: 0),
        15,
      ),
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 22, minute: 0),
      intervalMinutes: 60,
      enabled: true,
    ),
    HydrationAlarm(
      id: 'workout',
      label: 'Workout hydration boost',
      scheduleType: AlarmScheduleType.equalIntervals,
      reminderTimes: generateEqualIntervalTimes(
        const TimeOfDay(hour: 17, minute: 0),
        const TimeOfDay(hour: 18, minute: 30),
        5,
      ),
      startTime: const TimeOfDay(hour: 17, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 30),
      intervalMinutes: 20,
      enabled: false,
    ),
    HydrationAlarm(
      id: 'winddown',
      label: 'Wind-down reminder',
      scheduleType: AlarmScheduleType.custom,
      reminderTimes: [
        const TimeOfDay(hour: 20, minute: 0),
        const TimeOfDay(hour: 21, minute: 15),
        const TimeOfDay(hour: 22, minute: 30),
      ],
      tone: AlarmTone.gentleWave,
      enabled: true,
    ),
  ];

  void _toggleAlarm(int index, bool value) {
    setState(() {
      _alarms[index] = _alarms[index].copyWith(enabled: value);
    });
  }

  Future<void> _openEditor({int? index}) async {
    final existing = index != null ? _alarms[index] : null;

    final result = await Navigator.of(context).push<_AlarmEditorResult>(
      MaterialPageRoute(builder: (_) => _AlarmEditorScreen(initial: existing)),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (result.deleted) {
        if (index != null) _alarms.removeAt(index);
      } else if (result.alarm != null) {
        if (index != null) {
          _alarms[index] = result.alarm!;
        } else {
          _alarms.add(result.alarm!);
        }
      }
    });
  }

  Future<void> _confirmDelete(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: Text('Remove "${_alarms[index].label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      setState(() => _alarms.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final additionalAlarms = _alarms.length > 1 ? _alarms.sublist(1) : const <HydrationAlarm>[];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Alarms',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When Hydrate reminds you to drink',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AlarmCard(
                    alarm: _alarms[0],
                    primary: true,
                    onToggle: (v) => _toggleAlarm(0, v),
                    onTap: () => _openEditor(index: 0),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Additional alarms',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < additionalAlarms.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlarmCard(
                        alarm: additionalAlarms[i],
                        primary: false,
                        onToggle: (v) => _toggleAlarm(i + 1, v),
                        onTap: () => _openEditor(index: i + 1),
                        onDelete: () => _confirmDelete(i + 1),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AddAlarmButton(onTap: () => _openEditor()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alarm card (visual design unchanged from before, now data-driven)
// ---------------------------------------------------------------------------

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.primary,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
  });

  final HydrationAlarm alarm;
  final bool primary;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alarm.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  Switch(
                    value: alarm.enabled,
                    onChanged: onToggle,
                    activeTrackColor: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AlarmDetail(
                      icon: Icons.repeat_rounded,
                      label: 'Schedule',
                      value: alarm.scheduleSummary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AlarmDetail(
                      icon: Icons.wb_sunny_outlined,
                      label: 'From',
                      value: alarm.firstReminder.format(context),
                    ),
                  ),
                  Expanded(
                    child: _AlarmDetail(
                      icon: Icons.nights_stay_outlined,
                      label: 'Until',
                      value: alarm.lastReminder.format(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmDetail extends StatelessWidget {
  const _AlarmDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddAlarmButton extends StatelessWidget {
  const _AddAlarmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Add alarm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alarm editor — multi-step creation/edit flow
// ---------------------------------------------------------------------------

/// What the editor screen handed back: either a saved alarm, a delete
/// request, or (via a plain `null` pop) a cancel.
class _AlarmEditorResult {
  const _AlarmEditorResult.saved(this.alarm) : deleted = false;
  const _AlarmEditorResult.deleted() : alarm = null, deleted = true;

  final HydrationAlarm? alarm;
  final bool deleted;
}

class _AlarmEditorScreen extends StatefulWidget {
  const _AlarmEditorScreen({this.initial});

  final HydrationAlarm? initial;

  @override
  State<_AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<_AlarmEditorScreen> {
  static const int _minCount = 1;
  static const int _maxCount = 12;
  static const List<String> _stepTitles = [
    'How many reminders?',
    'Choose a schedule',
    'Tone & label',
    'Review & save',
  ];

  int _step = 0;

  late int _count;
  late AlarmScheduleType _scheduleType;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<TimeOfDay> _customTimes;
  late AlarmTone _tone;
  late TextEditingController _labelController;
  late bool _enabled;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _count = initial?.reminderTimes.length ?? 6;
    _scheduleType = initial?.scheduleType ?? AlarmScheduleType.equalIntervals;
    _startTime = initial?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = initial?.endTime ?? const TimeOfDay(hour: 20, minute: 0);
    _tone = initial?.tone ?? AlarmTone.defaultTone;
    _enabled = initial?.enabled ?? true;
    _labelController = TextEditingController(
      text: initial?.label ?? 'Hydration reminders',
    );

    _customTimes = initial != null && initial.scheduleType == AlarmScheduleType.custom
        ? List.of(initial.reminderTimes)
        : _defaultCustomTimes(_count);
  }

  List<TimeOfDay> _defaultCustomTimes(int count) {
    return generateEqualIntervalTimes(_startTime, _endTime, count);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _setCount(int value) {
    final clamped = value.clamp(_minCount, _maxCount).toInt();
    setState(() {
      _count = clamped;
      _customTimes = _resizeCustomTimes(_customTimes, clamped);
    });
  }

  List<TimeOfDay> _resizeCustomTimes(List<TimeOfDay> current, int newCount) {
    if (newCount == current.length) return current;
    if (newCount < current.length) {
      return current.sublist(0, newCount);
    }
    final extra = generateEqualIntervalTimes(_startTime, _endTime, newCount)
        .sublist(current.length);
    return [...current, ...extra];
  }

  List<TimeOfDay> get _previewTimes {
    if (_scheduleType == AlarmScheduleType.equalIntervals) {
      return generateEqualIntervalTimes(_startTime, _endTime, _count);
    }
    final sorted = List.of(_customTimes)..sort(_compareTimeOfDay);
    return sorted;
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _count >= _minCount;
      case 1:
        if (_scheduleType == AlarmScheduleType.equalIntervals) {
          return _toMinutes(_endTime) != _toMinutes(_startTime);
        }
        return _customTimes.length == _count;
      default:
        return true;
    }
  }

  void _goNext() {
    if (_step < _stepTitles.length - 1) {
      setState(() => _step += 1);
    } else {
      _save();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final times = _previewTimes;
    final alarm = HydrationAlarm(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      label: _labelController.text.trim().isEmpty
          ? 'Hydration reminders'
          : _labelController.text.trim(),
      scheduleType: _scheduleType,
      reminderTimes: times,
      enabled: _enabled,
      startTime: _scheduleType == AlarmScheduleType.equalIntervals ? _startTime : null,
      endTime: _scheduleType == AlarmScheduleType.equalIntervals ? _endTime : null,
      intervalMinutes: _scheduleType == AlarmScheduleType.equalIntervals
          ? equalIntervalStepMinutes(_startTime, _endTime, _count)
          : null,
      tone: _tone,
    );
    Navigator.of(context).pop(_AlarmEditorResult.saved(alarm));
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: const Text('This alarm schedule will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      Navigator.of(context).pop(const _AlarmEditorResult.deleted());
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _pickCustomTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTimes[index],
    );
    if (picked == null) return;
    setState(() => _customTimes[index] = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit alarm' : 'New alarm'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  for (var i = 0; i < _stepTitles.length; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        margin: EdgeInsets.only(right: i == _stepTitles.length - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _stepTitles[_step],
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: _buildStepBody(context),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_step == 0 ? 'Cancel' : 'Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _canGoNext ? _goNext : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_step == _stepTitles.length - 1 ? 'Save' : 'Next'),
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
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _CountStep(count: _count, onChanged: _setCount, min: _minCount, max: _maxCount);
      case 1:
        return _ScheduleStep(
          scheduleType: _scheduleType,
          onTypeChanged: (type) => setState(() => _scheduleType = type),
          startTime: _startTime,
          endTime: _endTime,
          onPickStart: () => _pickTime(isStart: true),
          onPickEnd: () => _pickTime(isStart: false),
          customTimes: _customTimes,
          onPickCustomTime: _pickCustomTime,
        );
      case 2:
        return _ToneAndLabelStep(
          labelController: _labelController,
          tone: _tone,
          onToneChanged: (tone) => setState(() => _tone = tone),
          enabled: _enabled,
          onEnabledChanged: (v) => setState(() => _enabled = v),
        );
      default:
        return _PreviewStep(
          label: _labelController.text.trim().isEmpty
              ? 'Hydration reminders'
              : _labelController.text.trim(),
          times: _previewTimes,
          tone: _tone,
          scheduleType: _scheduleType,
        );
    }
  }
}

// --- Step 1: how many reminders --------------------------------------------

class _CountStep extends StatelessWidget {
  const _CountStep({
    required this.count,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final int count;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many times a day would you like to be reminded to drink water?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: count > min ? () => onChanged(count - 1) : null,
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: count < max ? () => onChanged(count + 1) : null,
              ),
            ],
          ),
        ),
        Center(
          child: Text(
            'reminders per day',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Material(
      color: colorScheme.onSurface.withValues(alpha: enabled ? 0.05 : 0.02),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: enabled ? 0.8 : 0.3),
          ),
        ),
      ),
    );
  }
}

// --- Step 2: schedule type + config -----------------------------------------

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    required this.scheduleType,
    required this.onTypeChanged,
    required this.startTime,
    required this.endTime,
    required this.onPickStart,
    required this.onPickEnd,
    required this.customTimes,
    required this.onPickCustomTime,
  });

  final AlarmScheduleType scheduleType;
  final ValueChanged<AlarmScheduleType> onTypeChanged;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final List<TimeOfDay> customTimes;
  final ValueChanged<int> onPickCustomTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ScheduleTypeCard(
                title: 'Equal intervals',
                description: 'Evenly spaced between a start and end time',
                icon: Icons.timeline_rounded,
                selected: scheduleType == AlarmScheduleType.equalIntervals,
                onTap: () => onTypeChanged(AlarmScheduleType.equalIntervals),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScheduleTypeCard(
                title: 'Custom',
                description: 'Set each reminder time yourself',
                icon: Icons.tune_rounded,
                selected: scheduleType == AlarmScheduleType.custom,
                onTap: () => onTypeChanged(AlarmScheduleType.custom),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (scheduleType == AlarmScheduleType.equalIntervals) ...[
          _SettingsCard(
            children: [
              _TimeRow(
                icon: Icons.wb_sunny_outlined,
                label: 'Start time',
                time: startTime,
                onTap: onPickStart,
              ),
              _RowDivider(),
              _TimeRow(
                icon: Icons.nights_stay_outlined,
                label: 'End time',
                time: endTime,
                onTap: onPickEnd,
              ),
            ],
          ),
        ] else ...[
          _SettingsCard(
            children: [
              for (var i = 0; i < customTimes.length; i++) ...[
                _TimeRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Reminder ${i + 1}',
                  time: customTimes[i],
                  onTap: () => onPickCustomTime(i),
                ),
                if (i != customTimes.length - 1) _RowDivider(),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ScheduleTypeCard extends StatelessWidget {
  const _ScheduleTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.onSurface.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Step 3: tone + label + enabled ----------------------------------------

class _ToneAndLabelStep extends StatelessWidget {
  const _ToneAndLabelStep({
    required this.labelController,
    required this.tone,
    required this.onToneChanged,
    required this.enabled,
    required this.onEnabledChanged,
  });

  final TextEditingController labelController;
  final AlarmTone tone;
  final ValueChanged<AlarmTone> onToneChanged;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Label',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: labelController,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'e.g. Hydration reminders',
            filled: true,
            fillColor: colorScheme.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Alarm tone',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Placeholder selection for now — native ringtone picking comes later.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in AlarmTone.values)
              _ToneChip(tone: t, selected: tone == t, onTap: () => onToneChanged(t)),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Enabled',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: onEnabledChanged,
                    activeTrackColor: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({required this.tone, required this.selected, required this.onTap});

  final AlarmTone tone;
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tone.icon,
                size: 16,
                color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                tone.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Step 4: preview ---------------------------------------------------------

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.label,
    required this.times,
    required this.tone,
    required this.scheduleType,
  });

  final String label;
  final List<TimeOfDay> times;
  final AlarmTone tone;
  final AlarmScheduleType scheduleType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(Icons.water_drop_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      scheduleType == AlarmScheduleType.equalIntervals
                          ? 'Equal intervals · ${times.length} reminders'
                          : 'Custom · ${times.length} reminders',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(tone.icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Reminder times',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        _SettingsCard(
          children: [
            for (var i = 0; i < times.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.water_drop_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      times[i].format(context),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (i != times.length - 1) _RowDivider(),
            ],
          ],
        ),
      ],
    );
  }
}

// --- Shared small widgets for the editor -------------------------------------

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                time.format(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}