import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';

/// Nhân viên xem và phản hồi đánh giá của khách (dùng trong tab dược sĩ).
class StaffReviewReplyScreen extends StatefulWidget {
  const StaffReviewReplyScreen({super.key});

  @override
  State<StaffReviewReplyScreen> createState() => _StaffReviewReplyScreenState();
}

class _StaffReviewReplyScreenState extends State<StaffReviewReplyScreen> {
  final JsonApi _api = JsonApi();
  List<Map<String, dynamic>> _reviews = const [];
  bool _onlyPending = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = JsonApi.asMap(
        await _api.get(
          '/reviews/staff',
          query: {'replied': _onlyPending ? 'false' : 'true', 'size': 50},
        ),
      );
      _reviews = JsonApi.asList(data['content']);
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _reply(Map<String, dynamic> review) async {
    final controller = TextEditingController(
      text: review['staffReply']?.toString() ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Phản hồi: ${review['productName'] ?? ''}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập phản hồi gửi khách hàng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) {
      return;
    }
    try {
      await _api.put('/reviews/${review['id']}/reply', body: {'reply': text});
      messenger.showSnackBar(const SnackBar(content: Text('Đã gửi phản hồi')));
      await _load();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(JsonApi.message(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Chưa phản hồi'),
                selected: _onlyPending,
                onSelected: (_) {
                  setState(() => _onlyPending = true);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Đã phản hồi'),
                selected: !_onlyPending,
                onSelected: (_) {
                  setState(() => _onlyPending = false);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(_error ?? 'Không có đánh giá nào')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final rating = int.tryParse('${review['rating']}') ?? 0;
                      final reply = review['staffReply']?.toString();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${review['productName'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Row(
                                children: [
                                  for (var i = 1; i <= 5; i++)
                                    Icon(
                                      i <= rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 18,
                                      color: AppTheme.warning,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${review['userFullName'] ?? 'Khách hàng'}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((review['comment'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('${review['comment']}'),
                                ),
                              if (reply != null && reply.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(10),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Nhà thuốc: $reply'),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _reply(review),
                                  icon: const Icon(Icons.reply),
                                  label: Text(
                                    reply == null || reply.isEmpty
                                        ? 'Phản hồi'
                                        : 'Sửa phản hồi',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
