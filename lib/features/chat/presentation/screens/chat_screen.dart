import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_widgets.dart';

/// Chat của khách hàng: tab trợ lý tự động và tab dược sĩ.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _provider.openMyConversation();
      _provider.startPolling();
    });
  }

  @override
  void dispose() {
    _provider.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9FF),
        appBar: AppBar(
          title: const Text('Hỗ trợ & tư vấn'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.smart_toy_outlined), text: 'Trợ lý'),
              Tab(icon: Icon(Icons.medical_services_outlined), text: 'Dược sĩ'),
            ],
          ),
        ),
        body: const TabBarView(children: [_BotTab(), _PharmacistTab()]),
      ),
    );
  }
}

class _BotTab extends StatelessWidget {
  const _BotTab();

  static const List<String> _starters = [
    'Đơn hàng của tôi ở đâu?',
    'Nhà thuốc gần tôi',
    'Hướng dẫn upload đơn thuốc',
    'Tôi bị đau đầu',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.botMessages;
    final lastSuggestions = messages.isNotEmpty && messages.last.fromBot
        ? messages.last.suggestions
        : _starters;

    return Column(
      children: [
        Expanded(
          child: ChatMessageList(
            itemCount: messages.length + 1 + (provider.isBotTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const ChatBubble(
                  isMine: false,
                  senderLabel: 'Trợ lý An Tâm',
                  child: Text(
                    'Xin chào! Mình có thể giúp tra cứu đơn hàng, tồn kho, nhà thuốc gần bạn, '
                    'hướng dẫn gửi đơn thuốc hoặc gợi ý sản phẩm theo triệu chứng. '
                    'Thông tin chỉ mang tính tham khảo, hãy hỏi dược sĩ khi cần.',
                  ),
                );
              }
              if (index > messages.length) {
                return const ChatBubble(
                  isMine: false,
                  child: Text('Đang trả lời...'),
                );
              }
              final message = messages[index - 1];
              return ChatBubble(
                isMine: !message.fromBot,
                senderLabel: message.fromBot ? 'Trợ lý An Tâm' : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.fromBot
                            ? AppTheme.textPrimary
                            : Colors.white,
                        height: 1.35,
                      ),
                    ),
                    ...botProductCards(message.products),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final suggestion in lastSuggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(suggestion),
                    onPressed: provider.isBotTyping
                        ? null
                        : () => provider.askBot(suggestion),
                  ),
                ),
            ],
          ),
        ),
        ChatComposer(
          allowImage: false,
          isSending: provider.isBotTyping,
          hint: 'Hỏi trợ lý...',
          onSend: (text, _) => provider.askBot(text),
        ),
      ],
    );
  }
}

class _PharmacistTab extends StatelessWidget {
  const _PharmacistTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;

    if (provider.isLoading && provider.conversation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.conversation == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.errorMessage ?? 'Không kết nối được'),
            TextButton(
              onPressed: provider.openMyConversation,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: provider.pharmacistOnline
              ? const Color(0xFFE8F8F1)
              : const Color(0xFFFFF4E5),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: provider.pharmacistOnline
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.pharmacistOnline ? 'Dược sĩ đang trực tuyến' : 'Dược sĩ đang ngoại tuyến — tin nhắn sẽ được trả lời sớm nhất có thể',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Hãy mô tả triệu chứng hoặc câu hỏi về thuốc, dược sĩ sẽ tư vấn cho bạn. '
                      'Lịch sử tư vấn được lưu lại ở đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : ChatMessageList(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = !message.isFromStaff;
                    return ChatBubble(
                      isMine: mine,
                      senderLabel: mine
                          ? null
                          : 'Dược sĩ ${message.senderName}',
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
          onSend: (text, image) => provider.send(content: text, image: image),
        ),
      ],
    );
  }
}
