import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/chat_models.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_widgets.dart';

/// Màn hình dược sĩ trả lời một khách: gửi ảnh, gợi ý sản phẩm, ghi chú tư vấn.
class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  late final ChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _provider.openConversation(widget.conversation);
      _provider.startPolling();
    });
  }

  @override
  void dispose() {
    _provider.stopPolling();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final product = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ProductPickerSheet(),
    );
    if (product != null) {
      await _provider.send(
        content: 'Dược sĩ gợi ý: ${product.name}',
        productId: product.id,
      );
    }
  }

  void _openNotes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _NotesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;
    final conversation = provider.conversation ?? widget.conversation;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        title: Text(conversation.customerName),
        actions: [
          IconButton(
            tooltip: 'Ghi chú tư vấn',
            onPressed: _openNotes,
            icon: Badge(
              isLabelVisible: conversation.notes.isNotEmpty,
              label: Text('${conversation.notes.length}'),
              child: const Icon(Icons.sticky_note_2_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ChatMessageList(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine = message.isFromStaff;
                      return ChatBubble(
                        isMine: mine,
                        senderLabel: mine ? null : message.senderName,
                        time: chatTime(message.createdAt),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.hasImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: message.attachmentUrl!,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            if (message.content.isNotEmpty)
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: mine
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            if (message.productId != null)
                              ChatProductCard(
                                productId: message.productId!,
                                name: message.productName ?? 'Sản phẩm gợi ý',
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (provider.errorMessage != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFDECEC),
              padding: const EdgeInsets.all(8),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12.5),
              ),
            ),
          ChatComposer(
            isSending: provider.isSending,
            onPickProduct: _pickProduct,
            hint: 'Trả lời khách hàng...',
            onSend: (text, image) => provider.send(content: text, image: image),
          ),
        ],
      ),
    );
  }
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet();

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final notes = provider.conversation?.notes ?? const <ChatNote>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú tư vấn (chỉ nhân viên thấy)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có ghi chú',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          for (final note in notes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(note.content),
              subtitle: Text(
                '${note.authorName} • ${chatTime(note.createdAt)}',
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'VD: Khách dị ứng penicillin',
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: () async {
                  final text = _controller.text;
                  _controller.clear();
                  await provider.addNote(text);
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet();

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final JsonApi _api = JsonApi();
  final TextEditingController _controller = TextEditingController();
  List<ProductModel> _products = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    setState(() => _loading = true);
    try {
      final data = JsonApi.asMap(
        await _api.get('/products', query: {'keyword': keyword, 'size': 20}),
      );
      _products = JsonApi.asList(data['content'])
          .map(ProductModel.fromJson)
          .toList();
    } catch (_) {
      _products = const [];
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm sản phẩm gợi ý cho khách...',
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      for (final product in _products)
                        ListTile(
                          leading: const Icon(
                            Icons.medication_outlined,
                            color: AppTheme.primaryBlue,
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            CurrencyFormatter.format(product.price),
                          ),
                          onTap: () => Navigator.of(context).pop(product),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
