import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_widgets.dart';

/// Danh sách cuộc trò chuyện với khách dành cho dược sĩ.
class StaffChatListScreen extends StatefulWidget {
  const StaffChatListScreen({super.key});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ChatProvider>().loadStaffConversations();
      _timer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) {
          context.read<ChatProvider>().loadStaffConversations(silent: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final conversations = provider.staffConversations;

    return RefreshIndicator(
      onRefresh: provider.loadStaffConversations,
      child: provider.isLoading && conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 140),
                const Icon(
                  Icons.forum_outlined,
                  size: 56,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    provider.errorMessage ?? 'Chưa có khách nào nhắn tin',
                  ),
                ),
              ],
            )
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.lightBlue,
                    child: Text(
                      conversation.customerName.isEmpty
                          ? '?'
                          : String.fromCharCode(
                              conversation.customerName.runes.first,
                            ).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    conversation.customerName,
                    style: TextStyle(
                      fontWeight: conversation.unreadForStaff > 0
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    conversation.lastMessage ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chatTime(conversation.lastMessageAt ?? ''),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (conversation.unreadForStaff > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${conversation.unreadForStaff}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      AppRoutes.staffChat,
                      arguments: {'conversation': conversation},
                    );
                    if (context.mounted) {
                      context.read<ChatProvider>().loadStaffConversations(
                        silent: true,
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
