import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../chat/presentation/widgets/chat_widgets.dart';
import '../../data/support_models.dart';
import '../../providers/support_provider.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'RESOLVED':
      return AppTheme.success;
    case 'CLOSED':
      return AppTheme.textSecondary;
    case 'IN_PROGRESS':
      return AppTheme.primaryBlue;
    default:
      return AppTheme.warning;
  }
}

/// Danh sách yêu cầu hỗ trợ. `staffMode = true`: nhân viên xem mọi yêu cầu và lọc theo trạng thái.
class SupportTicketListScreen extends StatefulWidget {
  const SupportTicketListScreen({
    super.key,
    this.staffMode = false,
    this.embedded = false,
  });

  final bool staffMode;

  /// `true` khi nhúng trong tab (không có AppBar riêng).
  final bool embedded;

  @override
  State<SupportTicketListScreen> createState() =>
      _SupportTicketListScreenState();
}

class _SupportTicketListScreenState extends State<SupportTicketListScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final provider = context.read<SupportProvider>();
    if (widget.staffMode) {
      await provider.loadStaffTickets(status: _status);
    } else {
      await provider.loadMyTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final tickets = provider.tickets;

    final body = Column(
      children: [
        if (widget.staffMode)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _status == null,
                    onSelected: (_) {
                      setState(() => _status = null);
                      _load();
                    },
                  ),
                ),
                for (final entry in SupportTicket.statusLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _status == entry.key,
                      onSelected: (_) {
                        setState(() => _status = entry.key);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: provider.isLoading && tickets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : tickets.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      const Icon(
                        Icons.support_agent_outlined,
                        size: 56,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          provider.errorMessage ?? 'Chưa có yêu cầu hỗ trợ',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final color = _statusColor(ticket.status);
                      return Card(
                        child: ListTile(
                          title: Text(
                            ticket.subject,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${ticket.code} • ${ticket.categoryLabel}'
                            '${widget.staffMode ? ' • ${ticket.userName}' : ''}\n${chatTime(ticket.updatedAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            ticket.statusLabel,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              AppRoutes.supportTicketDetail,
                              arguments: {
                                'ticketId': ticket.id,
                                'staff': widget.staffMode,
                              },
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Yêu cầu hỗ trợ của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppRoutes.supportTicketForm);
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Gửi yêu cầu'),
      ),
      body: body,
    );
  }
}

class SupportTicketFormScreen extends StatefulWidget {
  const SupportTicketFormScreen({super.key, this.orderId});

  final String? orderId;

  @override
  State<SupportTicketFormScreen> createState() =>
      _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends State<SupportTicketFormScreen> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _content = TextEditingController();
  String _category = 'COMPLAINT';

  @override
  void dispose() {
    _subject.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<SupportProvider>();
    if (_subject.text.trim().isEmpty || _content.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và nội dung')),
      );
      return;
    }
    final ok = await provider.createTicket(
      category: _category,
      subject: _subject.text.trim(),
      content: _content.text.trim(),
      orderId: widget.orderId,
    );
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu, chúng tôi sẽ phản hồi sớm'),
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể gửi yêu cầu'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<SupportProvider>().isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Gửi yêu cầu hỗ trợ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final entry in SupportTicket.categoryLabels.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _category == entry.key,
                  onSelected: (_) => setState(() => _category = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Tiêu đề *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nội dung *',
              alignLabelWithHint: true,
            ),
          ),
          if (widget.orderId != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Yêu cầu sẽ được gắn với đơn hàng đang xem.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: Text(submitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }
}

class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
    this.staffMode = false,
  });

  final String ticketId;
  final bool staffMode;

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final TextEditingController _reply = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final provider = context.read<SupportProvider>();
      await provider.loadTicket(widget.ticketId);
      if (mounted) {
        setState(() => _status = provider.selected?.status);
      }
    });
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final provider = context.read<SupportProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final text = _reply.text.trim();
    final ticket = provider.selected;
    if (ticket == null) {
      return;
    }
    bool ok;
    if (widget.staffMode) {
      ok = await provider.staffUpdate(
        ticket.id,
        status: _status ?? ticket.status,
        reply: text,
      );
    } else {
      if (text.isEmpty) {
        return;
      }
      ok = await provider.reply(ticket.id, text);
    }
    if (ok) {
      _reply.clear();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Không thể gửi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final ticket = provider.selected;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: Text(ticket?.code ?? 'Yêu cầu hỗ trợ')),
      body: ticket == null
          ? Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : Text(provider.errorMessage ?? 'Không tìm thấy yêu cầu'),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.categoryLabel} • ${ticket.statusLabel}',
                        style: TextStyle(
                          color: _statusColor(ticket.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.staffMode) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final entry
                                in SupportTicket.statusLabels.entries)
                              ChoiceChip(
                                label: Text(entry.value),
                                selected: _status == entry.key,
                                onSelected: (_) =>
                                    setState(() => _status = entry.key),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ChatMessageList(
                    itemCount: ticket.messages.length,
                    itemBuilder: (context, index) {
                      final message = ticket.messages[index];
                      final mine = widget.staffMode
                          ? message.isStaff
                          : !message.isStaff;
                      return ChatBubble(
                        isMine: mine,
                        senderLabel: mine ? null : message.senderName,
                        time: chatTime(message.createdAt),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: mine ? Colors.white : AppTheme.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.staffMode)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: provider.isSubmitting ? null : _send,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Lưu trạng thái'),
                      ),
                    ),
                  ),
                if (ticket.status != 'CLOSED' || widget.staffMode)
                  ChatComposer(
                    allowImage: false,
                    isSending: provider.isSubmitting,
                    hint: widget.staffMode
                        ? 'Phản hồi khách (có thể để trống)...'
                        : 'Nhập phản hồi...',
                    onSend: (text, _) async {
                      _reply.text = text;
                      await _send();
                    },
                  ),
              ],
            ),
    );
  }
}
