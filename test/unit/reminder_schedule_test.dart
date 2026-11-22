import 'package:an_tam_pharma/features/reminder/data/models/medication_reminder.dart';
import 'package:an_tam_pharma/features/reminder/data/models/reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final daily = MedicationReminder(
    id: 'r1',
    medicineName: 'Paracetamol',
    times: const ['08:00', '20:00'],
    startDate: '2026-11-01',
  );
  final weekly = MedicationReminder(
    id: 'r2',
    medicineName: 'Thuốc tuần',
    times: const ['07:30'],
    repeat: 'WEEKLY',
    weekdays: const [1],
    startDate: '2026-11-01',
    endDate: '2026-11-30',
  );
  final monday = DateTime(2026, 11, 16);

  test('appliesOn tôn trọng ngày bắt đầu/kết thúc, thứ trong tuần và trạng thái bật/tắt', () {
    expect(daily.appliesOn(monday), isTrue);
    expect(weekly.appliesOn(monday), isTrue);
    expect(weekly.appliesOn(DateTime(2026, 11, 17)), isFalse);
    expect(weekly.appliesOn(DateTime(2026, 12, 7)), isFalse);
    expect(daily.appliesOn(DateTime(2026, 10, 31)), isFalse);
    expect(daily.copyWith(isActive: false).appliesOn(monday), isFalse);
  });

  test('slotsForDay sắp xếp theo giờ và gán đúng trạng thái', () {
    final logs = [
      const ReminderLog(
        reminderId: 'r1',
        medicineName: 'Paracetamol',
        date: '2026-11-16',
        time: '08:00',
        taken: true,
      ),
    ];
    final slots = ReminderSchedule.slotsForDay(
      [daily, weekly],
      logs,
      monday,
      DateTime(2026, 11, 16, 9, 0),
    );

    expect(slots.map((s) => s.time).toList(), ['07:30', '08:00', '20:00']);
    expect(slots[0].status, DoseStatus.missed);
    expect(slots[1].status, DoseStatus.taken);
    expect(slots[2].status, DoseStatus.upcoming);
  });

  test('trong 60 phút sau giờ uống thì ở trạng thái due', () {
    final slots = ReminderSchedule.slotsForDay(
      [daily],
      const [],
      monday,
      DateTime(2026, 11, 16, 8, 20),
    );
    expect(slots.first.status, DoseStatus.due);
  });

  test('adherence tính tỷ lệ đã uống', () {
    final logs = [
      const ReminderLog(
        reminderId: 'r1',
        medicineName: 'Paracetamol',
        date: '2026-11-16',
        time: '08:00',
        taken: true,
      ),
    ];
    final days = ReminderSchedule.adherence(
      [daily],
      logs,
      monday,
      2,
      DateTime(2026, 11, 16, 21, 0),
    );
    expect(days[0].total, 2);
    expect(days[0].taken, 1);
    expect(days[0].rate, 0.5);
    expect(days[1].taken, 0);
  });

  test('JSON round-trip giữ nguyên dữ liệu', () {
    final copy = MedicationReminder.fromJson(weekly.toJson());
    expect(copy.repeat, 'WEEKLY');
    expect(copy.weekdays, [1]);
    expect(copy.endDate, '2026-11-30');
  });
}
