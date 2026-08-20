import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/hydration_alarm_service.dart';
import '../../services/alarm_service.dart';
import '../../services/hydration_alarm_local_storage.dart';
import '../../services/hydration_service.dart';

enum AlarmScheduleType { equalIntervals, custom }

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

/// Model for the user's single hydration reminder schedule.
///
/// Structured so a real notification-scheduling model can replace this
/// without touching the widgets that render it. [reminderTimes] is always
/// the source of truth for what actually fires — it's computed once (either
/// evenly spaced or manually picked) rather than left for a future
/// notification system to derive from [startTime]/[endTime]. It is also
/// the same source of truth the "Upcoming alerts" section reads from, so
/// that section can never show a time the actual Android alarm doesn't
/// match.
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

  HydrationAlarm copyWith({String? id, bool? enabled}) {
    return HydrationAlarm(
      id: id ?? this.id,
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
///
/// A user has zero or one hydration alarm, never more. Local storage
/// (`HydrationAlarmLocalStorage`) is the immediate source of truth for
/// what this screen shows and what `AlarmService` schedules on-device —
/// the backend (`HydrationAlarmService`) is synchronized in the
/// background afterward and never blocks the UI.
///
/// One real subtlety this file handles explicitly: `HydrationAlarmService
/// .createAlarm()` takes no client-supplied id — the backend always mints
/// its own. Since the locally-generated id is what `AlarmService` already
/// used to schedule native alarms by the time the backend responds, every
/// subsequent edit/toggle/delete needs to target whichever id is
/// currently canonical, not necessarily the one it started with. See
/// `_pendingCreateSync` / `_resolveSyncId` / the reconciliation step in
/// `_syncCreateToBackend`.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final HydrationAlarmService _alarmService = HydrationAlarmService();
  final HydrationAlarmLocalStorage _localStorage = HydrationAlarmLocalStorage();

  HydrationAlarm? _alarm;

  /// Non-null only while a just-created alarm's backend id hasn't been
  /// confirmed yet. Resolves to the backend's assigned id, or `null` if
  /// the create failed outright (nothing to sync against).
  Future<String?>? _pendingCreateSync;

  @override
  void initState() {
    super.initState();
    _loadAlarmLocalFirst();
  }

  // --- Time / DTO conversion helpers -----------------------------------

  List<DateTime> _toDateTimes(List<TimeOfDay> times) {
    return times.map(_nextOccurrence).toList();
  }

  DateTime _nextOccurrence(TimeOfDay time) {
    final now = DateTime.now();

    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  HydrationAlarmDto _toDto(HydrationAlarm alarm) {
    return HydrationAlarmDto(
      id: alarm.id,
      label: alarm.label,
      scheduleType: alarm.scheduleType == AlarmScheduleType.equalIntervals
          ? 'equalIntervals'
          : 'custom',
      reminderTimes: alarm.reminderTimes.map(_timeToString).toList(),
      enabled: alarm.enabled,
      startTime: alarm.startTime != null
          ? _timeToString(alarm.startTime!)
          : null,
      endTime: alarm.endTime != null ? _timeToString(alarm.endTime!) : null,
      intervalMinutes: alarm.intervalMinutes,
      tone: alarm.tone.name,
    );
  }

  HydrationAlarm _fromDto(HydrationAlarmDto dto) {
    return HydrationAlarm(
      id: dto.id,
      label: dto.label,
      scheduleType: dto.scheduleType == 'equalIntervals'
          ? AlarmScheduleType.equalIntervals
          : AlarmScheduleType.custom,
      reminderTimes: dto.reminderTimes.map(_stringToTime).toList(),
      enabled: dto.enabled,
      startTime: dto.startTime != null ? _stringToTime(dto.startTime!) : null,
      endTime: dto.endTime != null ? _stringToTime(dto.endTime!) : null,
      intervalMinutes: dto.intervalMinutes,
      tone: AlarmTone.values.firstWhere(
        (tone) => tone.name == dto.tone,
        orElse: () => AlarmTone.defaultTone,
      ),
    );
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _stringToTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // --- Startup: local-first ----------------------------------------------

  Future<void> _loadAlarmLocalFirst() async {
    // 1. Local storage first. SharedPreferences, no network — this is the
    // ONLY thing the first frame after startup waits on.
    final local = await _localStorage.loadAlarm();

    if (!mounted) return;
    setState(() => _alarm = local);

    // 2. Restore Android scheduling from what's on-device, if enabled.
    if (local != null && local.enabled) {
      try {
        await AlarmService.instance.scheduleAlarm(
          id: local.id,
          label: local.label,
          reminderTimes: _toDateTimes(local.reminderTimes),
        );
      } catch (e) {
        debugPrint('Failed to restore alarm ${local.id}: $e');
      }
    }

    // 3. Backend touched only now, only in the background, and only to
    // cover "nothing local yet" (e.g. a fresh install / new device) — a
    // normal warm start never calls the backend just to display the
    // alarm. Every create/edit/toggle/delete below syncs itself
    // individually; this is purely a one-time catch-up on cold start.
    // Alarms loaded this way already carry the backend's real `_id`
    // (see HydrationAlarmDto.fromJson), so there's no reconciliation
    // needed here.
    if (local == null) {
      unawaited(_syncFromBackendIfEmpty());
    }
  }

  Future<void> _syncFromBackendIfEmpty() async {
    try {
      final alarms = await _alarmService.getAlarms();
      if (!mounted || _alarm != null || alarms.isEmpty) return;

      final remote = _fromDto(alarms.first);
      await _localStorage.saveAlarm(remote);

      if (!mounted) return;
      setState(() => _alarm = remote);

      if (remote.enabled) {
        await AlarmService.instance.scheduleAlarm(
          id: remote.id,
          label: remote.label,
          reminderTimes: _toDateTimes(remote.reminderTimes),
        );
      }
    } catch (e) {
      debugPrint('Background alarm sync failed (Render may be asleep): $e');
    }
  }

  // --- Toggle (enable/disable) --------------------------------------------

  Future<void> _toggleAlarm(bool value) async {
    final current = _alarm;
    if (current == null) return;

    final updated = current.copyWith(enabled: value);

    // Local-first: persist, reflect in the UI, and (de)schedule on-device
    // BEFORE anything touches the network.
    await _localStorage.saveAlarm(updated);
    if (!mounted) return;
    setState(() => _alarm = updated);

    if (value) {
      await AlarmService.instance.scheduleAlarm(
        id: updated.id,
        label: updated.label,
        reminderTimes: _toDateTimes(updated.reminderTimes),
      );
    } else {
      await AlarmService.instance.cancelAlarm(
        updated.id,
        reminderCount: updated.reminderTimes.length,
      );
    }

    unawaited(_syncToBackend(updated));
  }

  // --- Backend id resolution (see class doc comment) ----------------------

  /// If a create for this same alarm is still resolving its backend id,
  /// waits for it and returns that id. Otherwise [localId] is already
  /// canonical (either it always was — an alarm loaded from the backend —
  /// or a prior create already reconciled it). Returns `null` only when a
  /// create was pending and it failed, meaning there's nothing on the
  /// backend to sync against yet.
  Future<String?> _resolveSyncId(String localId) async {
    final pending = _pendingCreateSync;
    if (pending == null) return localId;
    return pending;
  }

  // --- Backend sync helpers --------------------------------------------------
  //
  // Each of these is fire-and-forget from the caller's perspective (never
  // awaited by anything that would block the UI) and never mutates local
  // state or _alarm on failure — a slow/asleep/unreachable Render instance
  // only means the change hasn't been mirrored to MongoDB yet, not that
  // the user's on-device alarm changes anything about what they see or
  // what actually rings.

  Future<void> _syncToBackend(HydrationAlarm alarm) async {
    final id = await _resolveSyncId(alarm.id);
    if (id == null) {
      debugPrint('Skipping backend sync — the create this alarm depended on never reached the backend.');
      return;
    }

    final dto = _toDto(alarm);
    try {
      final response = await _alarmService.updateAlarm(
        id: id,
        label: dto.label,
        scheduleType: dto.scheduleType,
        reminderTimes: dto.reminderTimes,
        enabled: dto.enabled,
        startTime: dto.startTime,
        endTime: dto.endTime,
        intervalMinutes: dto.intervalMinutes,
        tone: dto.tone,
      );
      if (!response.success) {
        debugPrint('Backend sync failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('Backend sync failed (Render may be asleep): $e');
    }
  }

  /// Creates the alarm on the backend and returns the id it was assigned.
  /// `HydrationAlarmService.createAlarm()` has no id parameter — the
  /// backend always mints its own — so if that id differs from the one
  /// used locally, this reconciles local storage, Android scheduling, and
  /// UI state to the backend's id. Returns `null` on failure.
  Future<String?> _syncCreateToBackend(HydrationAlarm alarm) async {
    final dto = _toDto(alarm);
    try {
      final response = await _alarmService.createAlarm(
        label: dto.label,
        scheduleType: dto.scheduleType,
        reminderTimes: dto.reminderTimes,
        enabled: dto.enabled,
        startTime: dto.startTime,
        endTime: dto.endTime,
        intervalMinutes: dto.intervalMinutes,
        tone: dto.tone,
      );

      if (!response.success || response.alarm == null) {
        debugPrint('Backend create sync failed: ${response.message}');
        return null;
      }

      final backendId = response.alarm!.id;

      if (backendId != alarm.id) {
        await _reconcileAlarmId(oldId: alarm.id, newId: backendId);
      }

      return backendId;
    } catch (e) {
      debugPrint('Backend create sync failed (Render may be asleep): $e');
      return null;
    }
  }

  /// Rewrites local storage, Android scheduling, and UI state to use
  /// [newId] instead of [oldId] — but only if the user still has the same
  /// alarm they created (they may have edited it further, in which case
  /// this picks up the LATEST content rather than the stale snapshot
  /// originally sent to the backend; or they may have deleted it, in
  /// which case there's nothing local left to reconcile — the delete's
  /// own background sync, via [_resolveSyncId], is what cleans up the
  /// now-orphaned backend record in that case).
  Future<void> _reconcileAlarmId({
    required String oldId,
    required String newId,
  }) async {
    final current = _alarm;
    if (current == null || current.id != oldId) return;

    final reconciled = current.copyWith(id: newId);

    // Cancel whatever might exist under the old id — harmless no-op if
    // there's nothing there (e.g. the user had already disabled it).
    await AlarmService.instance.cancelAlarm(
      oldId,
      reminderCount: current.reminderTimes.length,
    );

    if (current.enabled) {
      await AlarmService.instance.scheduleAlarm(
        id: newId,
        label: reconciled.label,
        reminderTimes: _toDateTimes(reconciled.reminderTimes),
      );
    }

    await _localStorage.saveAlarm(reconciled);

    if (mounted) {
      setState(() => _alarm = reconciled);
    }
  }

  // --- Editor entry point ----------------------------------------------------

  Future<void> _openEditor() async {
    final existing = _alarm;

    final result = await Navigator.of(context).push<_AlarmEditorResult>(
      MaterialPageRoute(builder: (_) => _AlarmEditorScreen(initial: existing)),
    );

    if (result == null || !mounted) return;

    if (result.deleted) {
      if (existing == null) return;
      await _deleteAlarm(existing);
      return;
    }

    final edited = result.alarm;
    if (edited == null) return;

    if (existing == null) {
      await _createAlarm(edited);
    } else {
      await _editAlarm(edited);
    }
  }

  Future<void> _createAlarm(HydrationAlarm alarm) async {
    // Guards against a second alarm: the Create button only ever renders
    // when _alarm is null, and this re-checks in case something changed
    // (e.g. the background empty-state sync above) while the editor was
    // open.
    if (_alarm != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have a hydration alarm.')),
      );
      return;
    }

    await _localStorage.saveAlarm(alarm);
    if (!mounted) return;
    setState(() => _alarm = alarm);

    if (alarm.enabled) {
      await AlarmService.instance.scheduleAlarm(
        id: alarm.id,
        label: alarm.label,
        reminderTimes: _toDateTimes(alarm.reminderTimes),
      );
    }

    final syncFuture = _syncCreateToBackend(alarm);
    _pendingCreateSync = syncFuture;
    unawaited(
      syncFuture.whenComplete(() {
        if (identical(_pendingCreateSync, syncFuture)) {
          _pendingCreateSync = null;
        }
      }),
    );
  }

  Future<void> _editAlarm(HydrationAlarm newAlarm) async {
    final oldAlarm = _alarm;
    if (oldAlarm == null) return;

    await _localStorage.saveAlarm(newAlarm);
    if (!mounted) return;
    setState(() => _alarm = newAlarm);

    await AlarmService.instance.rescheduleAlarm(
      id: newAlarm.id,
      label: newAlarm.label,
      oldReminderTimes: _toDateTimes(oldAlarm.reminderTimes),
      newReminderTimes: _toDateTimes(newAlarm.reminderTimes),
    );

    if (!newAlarm.enabled) {
      await AlarmService.instance.cancelAlarm(
        newAlarm.id,
        reminderCount: newAlarm.reminderTimes.length,
      );
    }

    unawaited(_syncToBackend(newAlarm));
  }

  Future<void> _deleteAlarm(HydrationAlarm alarm) async {
    // Local storage clear + Android cancellation both happen — and
    // complete — before the UI updates or the backend is touched. A
    // failed/slow backend delete must never leave the alarm reappearing
    // or still ringing.
    await _localStorage.deleteAlarm();
    await AlarmService.instance.cancelAlarm(
      alarm.id,
      reminderCount: alarm.reminderTimes.length,
    );

    if (!mounted) return;
    setState(() => _alarm = null);

    unawaited(_syncDelete(alarm.id));
  }

  Future<void> _syncDelete(String localId) async {
    // If a create for this alarm is still resolving, wait for the real
    // backend id first — otherwise a delete that happens moments after a
    // create would target an id the backend has never heard of, leaving
    // an orphaned record behind once the create finally lands.
    final id = await _resolveSyncId(localId);
    if (id == null) return; // create failed; nothing was ever persisted.

    try {
      final response = await _alarmService.deleteAlarm(id);
      if (!response.success) {
        debugPrint('Backend delete sync failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('Backend delete sync failed (Render may be asleep): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final alarm = _alarm;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              // Bottom inset stays large — it's clearance for the floating
              // glass bottom nav bar stacked above this screen in
              // MainScreen, not decorative whitespace.
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (alarm != null)
                    _AlarmCard(
                      alarm: alarm,
                      onToggle: _toggleAlarm,
                      onTap: _openEditor,
                    )
                  else
                    _EmptyAlarmState(onCreate: _openEditor),
                  if (alarm != null) _UpcomingAlertsSection(alarm: alarm),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAlarmState extends StatelessWidget {
  const _EmptyAlarmState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No hydration alarm set up yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 14),
        _AddAlarmButton(onTap: onCreate),
      ],
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
  });

  final HydrationAlarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: alarm.enabled ? 1 : 0.55,
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
                    Switch(
                      value: alarm.enabled,
                      onChanged: onToggle,
                      activeTrackColor: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AlarmDetail(
                  icon: Icons.repeat_rounded,
                  label: 'Schedule',
                  value: alarm.scheduleSummary(context),
                ),
                const SizedBox(height: 10),
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
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
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
                'Create alarm',
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
// Upcoming alerts — reads the SAME HydrationAlarm.reminderTimes used to
// schedule the actual Android alarms, plus the existing locally-cached
// DailyHydration from HydrationService, to show today's remaining
// reminders and a live-recalculated per-reminder water amount.
// ---------------------------------------------------------------------------

class _UpcomingAlertsSection extends StatefulWidget {
  const _UpcomingAlertsSection({required this.alarm});

  final HydrationAlarm alarm;

  @override
  State<_UpcomingAlertsSection> createState() => _UpcomingAlertsSectionState();
}

class _UpcomingAlertsSectionState extends State<_UpcomingAlertsSection> {
  final HydrationService _hydrationService = HydrationService();

  DailyHydration? _today;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Local cache read only (no network) — this just needs to notice
    // changes made elsewhere (water logged on Home, a passed reminder
    // time) without any cross-screen event plumbing.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant _UpcomingAlertsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alarm.reminderTimes != widget.alarm.reminderTimes ||
        oldWidget.alarm.enabled != widget.alarm.enabled) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    // getCachedToday() reads HydrationService's existing local
    // SharedPreferences cache (same cache profile_screen.dart / the goal
    // editor already read/wrote) — it never makes a network request, so
    // this can never block on Render.
    final cached = await _hydrationService.getCachedToday();
    if (!mounted) return;
    setState(() => _today = cached);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<TimeOfDay> get _upcomingTimes {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return widget.alarm.reminderTimes
        .where((t) => (t.hour * 60 + t.minute) > nowMinutes)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // An upcoming-alerts list for a disabled alarm would be misleading —
    // nothing will actually ring, so nothing "upcoming" to show.
    if (!widget.alarm.enabled) {
      return const SizedBox.shrink();
    }

    final upcoming = _upcomingTimes;

    final today = _today;
    final hasHydrationData = today != null;
    final goalReached = hasHydrationData && today.intakeMl >= today.goalMl;

    int? perAlertMl;
    if (hasHydrationData && !goalReached && upcoming.isNotEmpty) {
      final remainingRaw = today.goalMl - today.intakeMl;
      final remaining = remainingRaw < 0 ? 0.0 : remainingRaw.toDouble();
      final rawPerAlert = remaining / upcoming.length;
      var rounded = (rawPerAlert / 50).round() * 50;
      if (rounded == 0 && remaining > 0) rounded = remaining.round();
      perAlertMl = rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Upcoming alerts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const _CompactNotice(
            icon: Icons.check_circle_outline_rounded,
            title: 'No more alerts today',
            subtitle: 'Next reminders start tomorrow.',
          )
        else
          _SettingsCard(
            children: [
              for (var i = 0; i < upcoming.length; i++) ...[
                _UpcomingAlertRow(
                  time: upcoming[i],
                  amountLabel: goalReached
                      ? 'Goal reached'
                      : perAlertMl != null
                          ? '$perAlertMl ml'
                          : '—',
                ),
                if (i != upcoming.length - 1) _RowDivider(),
              ],
            ],
          ),
      ],
    );
  }
}

class _CompactNotice extends StatelessWidget {
  const _CompactNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
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

class _UpcomingAlertRow extends StatelessWidget {
  const _UpcomingAlertRow({required this.time, required this.amountLabel});

  final TimeOfDay time;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.water_drop_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.format(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Drink water',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alarm editor — multi-step creation/edit flow (unchanged)
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

    _customTimes =
        initial != null && initial.scheduleType == AlarmScheduleType.custom
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
    final extra = generateEqualIntervalTimes(
      _startTime,
      _endTime,
      newCount,
    ).sublist(current.length);
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
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      label: _labelController.text.trim().isEmpty
          ? 'Hydration reminders'
          : _labelController.text.trim(),
      scheduleType: _scheduleType,
      reminderTimes: times,
      enabled: _enabled,
      startTime: _scheduleType == AlarmScheduleType.equalIntervals
          ? _startTime
          : null,
      endTime: _scheduleType == AlarmScheduleType.equalIntervals
          ? _endTime
          : null,
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
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
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
                        margin: EdgeInsets.only(
                          right: i == _stepTitles.length - 1 ? 0 : 6,
                        ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                        child: Text(
                          _step == _stepTitles.length - 1 ? 'Save' : 'Next',
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
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _CountStep(
          count: _count,
          onChanged: _setCount,
          min: _minCount,
          max: _maxCount,
        );
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
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
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
              _ToneChip(
                tone: t,
                selected: tone == t,
                onTap: () => onToneChanged(t),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Enabled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
  const _ToneChip({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

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
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tone.icon,
                size: 16,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
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
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.water_drop_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
              Icon(
                tone.icon,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      times[i].format(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
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
              Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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