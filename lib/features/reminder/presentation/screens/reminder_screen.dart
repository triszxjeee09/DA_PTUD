import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/medication_reminder.dart';
import '../../data/models/reminder_schedule.dart';
import '../../providers/reminder_provider.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final owner = context.read<AuthProvider>().currentUser?.id;
    if (owner == null || !mounted) {
      return;
    }
    await context.read<ReminderProvider>().load(owner);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9FF),
        appBar: AppBar(
          title: const Text('Nhắc uống thuốc'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hôm nay'),
              Tab(text: 'Lịch nhắc'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.reminderForm),
          icon: const Icon(Icons.add_alarm),
          label: const Text('Thêm thuốc'),
        ),
        body: Column(
          children: [
            if (!provider.isOnline)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF4E5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text(
                  'Đang ngoại tuyến: dữ liệu lưu trên máy và tự đồng bộ khi có mạng. '
                  'Thông báo đúng giờ chỉ hoạt động với lịch đã đồng bộ.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            Expanded(
              child: provider.isLoading && provider.reminders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _TodayTab(onRefresh: _load),
                        _ListTab(onRefresh: _load),
                        const _HistoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(DoseStatus status) {
  switch (status) {
    case DoseStatus.taken:
      return AppTheme.success;
    case DoseStatus.skipped:
      return AppTheme.textSecondary;
    case DoseStatus.due:
      return AppTheme.warning;
    case DoseStatus.missed:
      return AppTheme.error;
    case DoseStatus.upcoming:
      return AppTheme.primaryBlue;
  }
}

String _statusLabel(DoseStatus status) {
  switch (status) {
    case DoseStatus.taken:
      return 'Đã uống';
    case DoseStatus.skipped:
      return 'Bỏ qua';
    case DoseStatus.due:
      return 'Đến giờ uống';
    case DoseStatus.missed:
      return 'Chưa uống';
    case DoseStatus.upcoming:
      return 'Sắp tới';
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final slots = provider.todaySlots();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: slots.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(
                  Icons.alarm_off_outlined,
                  size: 56,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(height: 12),
                Center(child: Text('Hôm nay chưa có liều thuốc nào')),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'Nhấn "Thêm thuốc" để tạo lịch nhắc',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _DoseCard(slot: slots[index]),
            ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.slot});

  final DoseSlot slot;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ReminderProvider>();
    final color = _statusColor(slot.status);
    final reminder = slot.reminder;
    final done =
        slot.status == DoseStatus.taken || slot.status == DoseStatus.skipped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slot.time,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      Text(
                        [
                          if (reminder.dosage.isNotEmpty) reminder.dosage,
                          if (reminder.memberName != null) reminder.memberName!,
                        ].join(' • '),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _statusLabel(slot.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (reminder.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reminder.note, style: const TextStyle(height: 1.4)),
            ],
            if (!done) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => provider.markDose(slot, taken: true),
                      icon: const Icon(Icons.check),
                      label: const Text('Đã uống'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => provider.markDose(slot, taken: false),
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  static const List<String> _weekdayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  String _repeatText(MedicationReminder reminder) {
    if (reminder.repeat == 'WEEKLY') {
      final days = [...reminder.weekdays]..sort();
      return days
          .where((d) => d >= 1 && d <= 7)
          .map((d) => _weekdayLabels[d - 1])
          .join(', ');
    }
    return 'Hằng ngày';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MedicationReminder reminder,
  ) async {
    final provider = context.read<ReminderProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lịch nhắc'),
        content: Text('Xóa lịch nhắc "${reminder.medicineName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.delete(reminder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.reminders;

    if (reminders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(height: 12),
            Center(child: Text('Chưa có lịch nhắc nào')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                        if (reminder.dosage.isNotEmpty)
                          Text(
                            reminder.dosage,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final time in reminder.times)
                              Chip(
                                label: Text(time),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: AppTheme.lightBlue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_repeatText(reminder)} • từ ${reminder.startDate}'
                          '${reminder.endDate == null ? '' : ' đến ${reminder.endDate}'}'
                          '${reminder.memberName == null ? '' : ' • ${reminder.memberName}'}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: reminder.isActive,
                        onChanged: (_) => provider.toggleActive(reminder),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Sửa',
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.reminderForm,
                              arguments: {'reminder': reminder},
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () => _confirmDelete(context, reminder),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final days = context.watch<ReminderProvider>().adherence(14);
    final total = days.fold<int>(0, (sum, d) => sum + d.total);
    final taken = days.fold<int>(0, (sum, d) => sum + d.taken);
    final rate = total == 0 ? 0.0 : taken / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tuân thủ 14 ngày gần nhất',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: rate,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Chưa có dữ liệu'
                      : '$taken/$total liều đã uống (${(rate * 100).round()}%)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final day in days)
          if (day.total > 0)
            ListTile(
              dense: true,
              leading: Icon(
                day.taken == day.total
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: day.taken == day.total
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
              title: Text(
                '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}',
              ),
              trailing: Text('${day.taken}/${day.total} liều'),
            ),
      ],
    );
  }
}
