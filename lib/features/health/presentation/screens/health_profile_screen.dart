import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/health_member.dart';
import '../../data/models/health_metric.dart';
import '../../domain/health_assessment.dart';
import '../../providers/health_provider.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final owner = context.read<AuthProvider>().currentUser?.id;
    if (owner != null && mounted) {
      await context.read<HealthProvider>().load(owner);
    }
  }

  Future<void> _delete(HealthMember member) async {
    final provider = context.read<HealthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hồ sơ'),
        content: Text('Xóa hồ sơ của ${member.name} và toàn bộ chỉ số đã ghi?'),
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
    if (ok != true) {
      return;
    }
    final error = await provider.deleteMember(member);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthProvider>();
    final members = provider.members;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Hồ sơ sức khỏe gia đình')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.healthMemberForm),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm thành viên'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading && members.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: members.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == members.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Thông tin dị ứng và bệnh nền giúp dược sĩ tư vấn an toàn hơn. '
                        '${HealthAssessor.disclaimer}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    );
                  }
                  return _MemberCard(
                    member: members[index],
                    onDelete: () => _delete(members[index]),
                  );
                },
              ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onDelete});

  final HealthMember member;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final age = member.ageAt(DateTime.now());
    final bmi = HealthAssessor.bmi(member.heightCm, member.weightKg);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.lightBlue,
                  child: Text(
                    member.name.isEmpty
                        ? '?'
                        : String.fromCharCode(member.name.runes.first).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        [
                          member.relationLabel,
                          if (age != null) '$age tuổi',
                          if (bmi != null) 'BMI ${bmi.toStringAsFixed(1)}',
                        ].join(' • '),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.healthMemberForm,
                    arguments: {'member': member},
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (member.relation != 'SELF')
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (member.allergies.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dị ứng: ${member.allergies}',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (member.conditions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Bệnh nền: ${member.conditions}'),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final type in const [
                  HealthMetric.bloodPressure,
                  HealthMetric.glucose,
                  HealthMetric.weight,
                ])
                  ActionChip(
                    label: Text(HealthMetric.typeLabels[type]!),
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.healthMetric,
                      arguments: {'type': type, 'memberId': member.id},
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
