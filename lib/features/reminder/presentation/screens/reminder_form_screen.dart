import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../health/providers/health_provider.dart';
import '../../data/models/medication_reminder.dart';
import '../../providers/reminder_provider.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key, this.reminder});

  final MedicationReminder? reminder;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  static const List<String> _weekdayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _noteController;
  late List<String> _times;
  late String _repeat;
  late Set<int> _weekdays;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _memberId;
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _nameController = TextEditingController(text: reminder?.medicineName ?? '');
    _dosageController = TextEditingController(text: reminder?.dosage ?? '');
    _noteController = TextEditingController(text: reminder?.note ?? '');
    _times = [
      ...(reminder?.times ?? const ['08:00']),
    ];
    _repeat = reminder?.repeat ?? 'DAILY';
    _weekdays = {...(reminder?.weekdays ?? const <int>[])};
    _startDate = DateTime.tryParse(reminder?.startDate ?? '') ?? DateTime.now();
    _endDate = DateTime.tryParse(reminder?.endDate ?? '');
    _memberId = reminder?.memberId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final owner = context.read<AuthProvider>().currentUser?.id;
      final health = context.read<HealthProvider>();
      if (owner != null && health.members.isEmpty) {
        health.load(owner);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) {
      return;
    }
    final text = _formatTime(picked);
    if (!_times.contains(text)) {
      setState(() => _times = [..._times, text]..sort());
    }
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? (_endDate ?? _startDate) : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_nameController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên thuốc')),
      );
      return;
    }
    if (_times.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một giờ uống')),
      );
      return;
    }
    if (_repeat == 'WEEKLY' && _weekdays.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn các thứ trong tuần')),
      );
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }

    setState(() => _saving = true);
    final health = context.read<HealthProvider>();
    final member = health.memberById(_memberId);
    final reminder = MedicationReminder(
      id: widget.reminder?.id ?? 'rem-${DateTime.now().microsecondsSinceEpoch}',
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      times: _times,
      repeat: _repeat,
      weekdays: _weekdays.toList()..sort(),
      startDate: MedicationReminder.dateKey(_startDate),
      endDate: _endDate == null ? null : MedicationReminder.dateKey(_endDate!),
      note: _noteController.text.trim(),
      memberId: member?.id,
      memberName: member?.name,
      isActive: widget.reminder?.isActive ?? true,
    );

    await context.read<ReminderProvider>().save(reminder);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<HealthProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa lịch nhắc' : 'Thêm lịch nhắc'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tên thuốc *',
              prefixIcon: Icon(Icons.medication_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Liều dùng (VD: 1 viên sau ăn)',
              prefixIcon: Icon(Icons.local_pharmacy_outlined),
            ),
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: members.any((m) => m.id == _memberId)
                  ? _memberId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Người dùng thuốc',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Không chọn'),
                ),
                for (final member in members)
                  DropdownMenuItem<String?>(
                    value: member.id,
                    child: Text('${member.name} (${member.relationLabel})'),
                  ),
              ],
              onChanged: (value) => setState(() => _memberId = value),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Giờ uống', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final time in _times)
                InputChip(
                  label: Text(time),
                  onDeleted: _times.length <= 1
                      ? null
                      : () => setState(
                          () =>
                              _times = _times.where((t) => t != time).toList(),
                        ),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Thêm giờ'),
                onPressed: _addTime,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Lặp lại', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Hằng ngày'),
                selected: _repeat == 'DAILY',
                onSelected: (_) => setState(() => _repeat = 'DAILY'),
              ),
              ChoiceChip(
                label: const Text('Theo thứ trong tuần'),
                selected: _repeat == 'WEEKLY',
                onSelected: (_) => setState(() => _repeat = 'WEEKLY'),
              ),
            ],
          ),
          if (_repeat == 'WEEKLY') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(_weekdayLabels[day - 1]),
                    selected: _weekdays.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isEnd: false),
                  icon: const Icon(Icons.event),
                  label: Text(
                    'Bắt đầu: ${MedicationReminder.dateKey(_startDate)}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isEnd: true),
                  icon: const Icon(Icons.event_available),
                  label: Text(
                    _endDate == null
                        ? 'Không kết thúc'
                        : 'Đến: ${MedicationReminder.dateKey(_endDate!)}',
                  ),
                ),
              ),
            ],
          ),
          if (_endDate != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _endDate = null),
                child: const Text('Bỏ ngày kết thúc'),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (VD: uống sau ăn no)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu lịch nhắc'),
          ),
        ],
      ),
    );
  }
}
