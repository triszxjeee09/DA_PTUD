import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../providers/support_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupportProvider>().loadHelpCenter();
      }
    });
  }

  Future<void> _call(String hotline) async {
    final messenger = ScaffoldMessenger.of(context);
    final digits = hotline.replaceAll(RegExp(r'[^0-9+]'), '');
    final opened = await launchUrl(Uri(scheme: 'tel', path: digits));
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể mở trình quay số. Hotline: $hotline'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final info = provider.info;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Trung tâm trợ giúp')),
      body: RefreshIndicator(
        onRefresh: provider.loadHelpCenter,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (info != null)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.lightBlue,
                    child: Icon(
                      Icons.phone_in_talk_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  title: Text(
                    'Hotline ${info.hotline}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${info.workingHours}\n${info.email}'),
                  isThreeLine: true,
                  trailing: FilledButton(
                    onPressed: () => _call(info.hotline),
                    child: const Text('Gọi'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat dược sĩ',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.chat),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.edit_note_outlined,
                    label: 'Gửi yêu cầu',
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.supportTicketForm),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.list_alt_outlined,
                    label: 'Yêu cầu của tôi',
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.supportTickets),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Câu hỏi thường gặp',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 8),
            if (provider.isLoading && provider.faqs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (provider.errorMessage != null && provider.faqs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(provider.errorMessage!),
              ),
            for (final faq in provider.faqs)
              Card(
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(
                    faq.question,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq.answer, style: const TextStyle(height: 1.45)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
