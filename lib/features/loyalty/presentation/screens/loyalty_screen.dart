import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/loyalty_provider.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LoyaltyProvider>().load();
      }
    });
  }

  Future<void> _redeem(String rewardId, String name, int points) async {
    final provider = context.read<LoyaltyProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi điểm'),
        content: Text('Dùng $points điểm để đổi "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    final code = await provider.redeem(rewardId);
    if (!mounted) {
      return;
    }
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Không thể đổi điểm')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi điểm thành công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mã voucher của bạn (dùng ở bước thanh toán):'),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkBlue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Sao chép'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoyaltyProvider>();
    final summary = provider.summary;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Điểm thưởng & hạng thành viên')),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: summary == null
            ? ListView(
                children: [
                  const SizedBox(height: 160),
                  Center(
                    child: provider.isLoading
                        ? const CircularProgressIndicator()
                        : Text(provider.errorMessage ?? 'Không có dữ liệu'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hạng ${summary.tierLabel}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${summary.points} điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: summary.progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary.nextTierLabel == null
                              ? 'Bạn đang ở hạng cao nhất'
                              : 'Còn ${summary.pointsToNextTier} điểm để lên hạng ${summary.nextTierLabel}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mỗi 1.000đ của đơn hàng hoàn tất được 1 điểm.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Đổi điểm lấy voucher',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  for (final reward in summary.rewards)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.lightBlue,
                          child: Icon(
                            Icons.card_giftcard,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        title: Text(
                          reward.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${reward.points} điểm • đơn từ ${CurrencyFormatter.format(reward.minOrderAmount)}',
                        ),
                        trailing: FilledButton(
                          onPressed:
                              provider.isRedeeming ||
                                  summary.points < reward.points
                              ? null
                              : () => _redeem(
                                  reward.id,
                                  reward.name,
                                  reward.points,
                                ),
                          child: const Text('Đổi'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Text(
                    'Lịch sử điểm',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  if (summary.history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Chưa có giao dịch điểm',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  for (final entry in summary.history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.reason),
                      subtitle: entry.createdAt == null
                          ? null
                          : Text(
                              '${entry.createdAt!.day.toString().padLeft(2, '0')}/${entry.createdAt!.month.toString().padLeft(2, '0')}/${entry.createdAt!.year}',
                            ),
                      trailing: Text(
                        '${entry.delta > 0 ? '+' : ''}${entry.delta}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: entry.delta >= 0
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
