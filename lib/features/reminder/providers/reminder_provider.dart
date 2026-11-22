import 'package:flutter/foundation.dart';

import '../../../core/sync/synced_collection.dart';
import '../data/models/medication_reminder.dart';
import '../data/models/reminder_schedule.dart';

/// Nhắc uống thuốc: SQLite trên máy (offline) + đồng bộ API; máy chủ gửi FCM
/// đúng giờ cho các lịch đã đồng bộ.
class ReminderProvider extends ChangeNotifier {
  ReminderProvider({SyncedCollection? reminders, SyncedCollection? logs})
    : _reminders =
          reminders ??
          SyncedCollection(
            kind: 'reminders',
            listPath: '/reminders',
            createPath: (_) => '/reminders',
            deletePath: (id) => '/reminders/$id',
          ),
      _logs =
          logs ??
          SyncedCollection(
            kind: 'reminder_logs',
            listPath: '/reminders/logs',
            createPath: (item) => '/reminders/${item['reminderId']}/logs',
            deletePath: (_) => null,
          );

  final SyncedCollection _reminders;
  final SyncedCollection _logs;

  String? _owner;
  List<MedicationReminder> _reminderList = const [];
  List<ReminderLog> _logList = const [];
  bool _isLoading = false;
  bool _isOnline = true;

  List<MedicationReminder> get reminders => _reminderList;
  List<ReminderLog> get logs => _logList;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  List<DoseSlot> todaySlots([DateTime? now]) {
    final current = now ?? DateTime.now();
    return ReminderSchedule.slotsForDay(
      _reminderList,
      _logList,
      DateTime(current.year, current.month, current.day),
      current,
    );
  }

  /// Liều gần nhất chưa uống (đang đến giờ hoặc sắp tới) trong hôm nay.
  DoseSlot? nextDose([DateTime? now]) {
    for (final slot in todaySlots(now)) {
      if (slot.status == DoseStatus.due || slot.status == DoseStatus.upcoming) {
        return slot;
      }
    }
    return null;
  }

  List<AdherenceDay> adherence(int days, [DateTime? now]) {
    final current = now ?? DateTime.now();
    return ReminderSchedule.adherence(
      _reminderList,
      _logList,
      DateTime(current.year, current.month, current.day),
      days,
      current,
    );
  }

  Future<void> load(String owner) async {
    if (_owner != owner) {
      _owner = owner;
      _reminderList = const [];
      _logList = const [];
    }
    _isLoading = true;
    notifyListeners();
    await _reloadLocal(owner);
    _isLoading = false;
    notifyListeners();

    final reminderOk = await _reminders.sync(owner);
    final logOk = await _logs.sync(owner);
    _isOnline = reminderOk && logOk;
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<void> save(MedicationReminder reminder) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    await _reminders.save(owner, reminder.toJson());
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    await _reminders.remove(owner, id);
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<void> toggleActive(MedicationReminder reminder) {
    return save(reminder.copyWith(isActive: !reminder.isActive));
  }

  Future<void> markDose(DoseSlot slot, {required bool taken}) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    final log = ReminderLog(
      reminderId: slot.reminder.id,
      medicineName: slot.reminder.medicineName,
      date: slot.date,
      time: slot.time,
      taken: taken,
    );
    await _logs.save(owner, log.toJson());
    await _reloadLocal(owner);
    notifyListeners();
  }

  void resetIfUserChanged(String? userId) {
    if (_owner != null && _owner != userId) {
      _owner = null;
      _reminderList = const [];
      _logList = const [];
    }
  }

  void clear() {
    _owner = null;
    _reminderList = const [];
    _logList = const [];
    notifyListeners();
  }

  Future<void> _reloadLocal(String owner) async {
    final reminders = await _reminders.load(owner);
    final logs = await _logs.load(owner);
    _reminderList = reminders.map(MedicationReminder.fromJson).toList();
    _logList = logs.map(ReminderLog.fromJson).toList();
  }
}
