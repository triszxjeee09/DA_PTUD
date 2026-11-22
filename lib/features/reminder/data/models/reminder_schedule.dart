import 'medication_reminder.dart';

enum DoseStatus { taken, skipped, upcoming, due, missed }

/// Một liều thuốc cần uống trong ngày.
class DoseSlot {
  const DoseSlot({
    required this.reminder,
    required this.date,
    required this.time,
    required this.dueAt,
    required this.status,
    this.log,
  });

  final MedicationReminder reminder;
  final String date;
  final String time;
  final DateTime dueAt;
  final DoseStatus status;
  final ReminderLog? log;
}

class AdherenceDay {
  const AdherenceDay({
    required this.date,
    required this.taken,
    required this.total,
  });

  final DateTime date;
  final int taken;
  final int total;

  double get rate => total == 0 ? 0 : taken / total;
}

class ReminderSchedule {
  const ReminderSchedule._();

  static DateTime _dueAt(DateTime day, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  /// Danh sách liều của một ngày, sắp xếp theo giờ.
  static List<DoseSlot> slotsForDay(
    List<MedicationReminder> reminders,
    List<ReminderLog> logs,
    DateTime day,
    DateTime now, {
    Duration dueWindow = const Duration(minutes: 60),
  }) {
    final key = MedicationReminder.dateKey(day);
    final byId = {for (final log in logs) log.id: log};
    final slots = <DoseSlot>[];

    for (final reminder in reminders) {
      if (!reminder.appliesOn(day)) {
        continue;
      }
      for (final time in reminder.times) {
        final dueAt = _dueAt(day, time);
        final log = byId[ReminderLog.idFor(reminder.id, key, time)];
        final DoseStatus status;
        if (log != null) {
          status = log.taken ? DoseStatus.taken : DoseStatus.skipped;
        } else if (now.isBefore(dueAt)) {
          status = DoseStatus.upcoming;
        } else if (now.difference(dueAt) <= dueWindow) {
          status = DoseStatus.due;
        } else {
          status = DoseStatus.missed;
        }
        slots.add(
          DoseSlot(
            reminder: reminder,
            date: key,
            time: time,
            dueAt: dueAt,
            status: status,
            log: log,
          ),
        );
      }
    }

    slots.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return slots;
  }

  /// Tỷ lệ tuân thủ của [days] ngày gần nhất tính đến [endDay] (mới nhất trước).
  static List<AdherenceDay> adherence(
    List<MedicationReminder> reminders,
    List<ReminderLog> logs,
    DateTime endDay,
    int days,
    DateTime now,
  ) {
    final result = <AdherenceDay>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime(endDay.year, endDay.month, endDay.day - i);
      final slots = slotsForDay(reminders, logs, day, now);
      final counted = slots.where((s) => s.status != DoseStatus.upcoming);
      result.add(
        AdherenceDay(
          date: day,
          taken: counted.where((s) => s.status == DoseStatus.taken).length,
          total: counted.length,
        ),
      );
    }
    return result;
  }
}
