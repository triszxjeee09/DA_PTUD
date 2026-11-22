import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/health_member.dart';
import '../../providers/health_provider.dart';

class HealthMemberFormScreen extends StatefulWidget {
  const HealthMemberFormScreen({super.key, this.member});

  final HealthMember? member;

  @override
  State<HealthMemberFormScreen> createState() => _HealthMemberFormScreenState();
}

class _HealthMemberFormScreenState extends State<HealthMemberFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _note;
  late String _relation;
  String? _gender;
  DateTime? _birthDate;
  bool _saving = false;

  bool get _isSelf => widget.member?.relation == 'SELF';

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    String fmt(double? v) => v == null
        ? ''
        : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
    _name = TextEditingController(text: m?.name ?? '');
    _height = TextEditingController(text: fmt(m?.heightCm));
    _weight = TextEditingController(text: fmt(m?.weightKg));
    _allergies = TextEditingController(text: m?.allergies ?? '');
    _conditions = TextEditingController(text: m?.conditions ?? '');
    _note = TextEditingController(text: m?.note ?? '');
    _relation = m?.relation ?? 'OTHER';
    _gender = m?.gender;
    _birthDate = DateTime.tryParse(m?.birthDate ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _height, _weight, _allergies, _conditions, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên thành viên')),
      );
      return;
    }
    double? number(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final height = number(_height);
    final weight = number(_weight);
    if ((height != null && (height < 30 || height > 250)) ||
        (weight != null && (weight <= 0 || weight > 400))) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chiều cao hoặc cân nặng không hợp lệ')),
      );
      return;
    }

    setState(() => _saving = true);
    final birth = _birthDate;
    final member = HealthMember(
      id: widget.member?.id ?? 'hm-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      relation: _relation,
      gender: _gender,
      birthDate: birth == null
          ? null
          : '${birth.year}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}',
      heightCm: height,
      weightKg: weight,
      allergies: _allergies.text.trim(),
      conditions: _conditions.text.trim(),
      note: _note.text.trim(),
    );
    await context.read<HealthProvider>().saveMember(member);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? 'Thêm thành viên' : 'Sửa hồ sơ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Họ tên *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _relation,
            decoration: const InputDecoration(labelText: 'Quan hệ'),
            items: [
              for (final entry in HealthMember.relationLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: _isSelf
                ? null
                : (value) => setState(() => _relation = value ?? 'OTHER'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Giới tính'),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Không rõ')),
              DropdownMenuItem<String?>(value: 'MALE', child: Text('Nam')),
              DropdownMenuItem<String?>(value: 'FEMALE', child: Text('Nữ')),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickBirthDate,
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              _birthDate == null
                  ? 'Chọn ngày sinh'
                  : 'Ngày sinh: ${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Chiều cao (cm)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _allergies,
            decoration: const InputDecoration(
              labelText: 'Dị ứng thuốc/thức ăn',
              prefixIcon: Icon(Icons.warning_amber_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditions,
            decoration: const InputDecoration(
              labelText: 'Bệnh nền (tiểu đường, huyết áp...)',
              prefixIcon: Icon(Icons.healing_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
          ),
        ],
      ),
    );
  }
}
