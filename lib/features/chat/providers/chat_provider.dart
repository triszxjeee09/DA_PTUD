import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/data/services/file_upload_service.dart';
import '../../../core/network/json_api.dart';
import '../data/chat_models.dart';
import '../data/chat_service.dart';

/// Chat với dược sĩ (polling API mỗi vài giây) và trợ lý tự động.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service, FileUploadService? uploadService})
    : _service = service ?? ChatService(),
      _uploadService = uploadService ?? FileUploadService();

  static const Duration pollInterval = Duration(seconds: 4);

  final ChatService _service;
  final FileUploadService _uploadService;

  String? _userId;
  ChatConversation? _conversation;
  List<ChatMessage> _messages = const [];
  List<ChatConversation> _staffConversations = const [];
  final List<BotMessage> _botMessages = [];
  bool _pharmacistOnline = false;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isBotTyping = false;
  bool _isStaffView = false;
  String? _errorMessage;
  Timer? _timer;
  bool _polling = false;

  ChatConversation? get conversation => _conversation;
  List<ChatMessage> get messages => _messages;
  List<ChatConversation> get staffConversations => _staffConversations;
  List<BotMessage> get botMessages => List.unmodifiable(_botMessages);
  bool get pharmacistOnline => _pharmacistOnline;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isBotTyping => _isBotTyping;
  String? get errorMessage => _errorMessage;

  int get staffUnreadTotal =>
      _staffConversations.fold<int>(0, (sum, c) => sum + c.unreadForStaff);

  /// Khách mở cuộc trò chuyện của mình.
  Future<void> openMyConversation() async {
    _isStaffView = false;
    _isLoading = true;
    _errorMessage = null;
    _conversation = null;
    _messages = const [];
    notifyListeners();
    try {
      final conversation = await _service.myConversation();
      _conversation = conversation;
      _messages = await _service.messages(conversation.id);
      _pharmacistOnline = await _service.pharmacistOnline();
      await _service.markRead(conversation.id);
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Dược sĩ mở cuộc trò chuyện của một khách.
  Future<void> openConversation(ChatConversation conversation) async {
    _isStaffView = true;
    _isLoading = true;
    _errorMessage = null;
    _conversation = conversation;
    _messages = const [];
    notifyListeners();
    try {
      _messages = await _service.messages(conversation.id);
      await _service.markRead(conversation.id);
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    final conversation = _conversation;
    if (_polling || conversation == null) {
      return;
    }
    _polling = true;
    try {
      final after = _messages.isEmpty ? null : _messages.last.createdAt;
      final fresh = await _service.messages(conversation.id, after: after);
      var changed = false;
      if (fresh.isNotEmpty) {
        final known = _messages.map((m) => m.id).toSet();
        final added = fresh.where((m) => !known.contains(m.id)).toList();
        if (added.isNotEmpty) {
          _messages = [..._messages, ...added];
          changed = true;
          await _service.markRead(conversation.id);
        }
      }
      if (!_isStaffView) {
        final online = await _service.pharmacistOnline();
        if (online != _pharmacistOnline) {
          _pharmacistOnline = online;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    } catch (_) {
      // Mất mạng tạm thời: bỏ qua, lần polling sau sẽ thử lại.
    } finally {
      _polling = false;
    }
  }

  Future<bool> send({
    String content = '',
    File? image,
    String? productId,
  }) async {
    final conversation = _conversation;
    if (conversation == null || _isSending) {
      return false;
    }
    final text = content.trim();
    if (text.isEmpty && image == null && productId == null) {
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      String? url;
      if (image != null) {
        final uploaded = await _uploadService.uploadImage(
          file: image,
          folder: 'chat',
        );
        url = uploaded.fileUrl;
      }
      final message = await _service.send(
        conversation.id,
        content: text,
        attachmentUrl: url,
        attachmentType: url == null ? null : 'IMAGE',
        productId: productId,
      );
      if (!_messages.any((m) => m.id == message.id)) {
        _messages = [..._messages, message];
      }
      return true;
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> askBot(String text) async {
    final question = text.trim();
    if (question.isEmpty || _isBotTyping) {
      return;
    }
    _botMessages.add(BotMessage(fromBot: false, text: question));
    _isBotTyping = true;
    notifyListeners();
    try {
      _botMessages.add(await _service.askBot(question));
    } catch (error) {
      _botMessages.add(BotMessage(fromBot: true, text: JsonApi.message(error)));
    } finally {
      _isBotTyping = false;
      notifyListeners();
    }
  }

  Future<void> loadStaffConversations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _staffConversations = await _service.staffConversations();
    } catch (error) {
      if (!silent) {
        _errorMessage = JsonApi.message(error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStaffPresence({required bool online}) async {
    try {
      await _service.setPresence(online: online);
    } catch (_) {
      // Không ảnh hưởng chức năng chính.
    }
  }

  Future<void> addNote(String text) async {
    final conversation = _conversation;
    if (conversation == null || text.trim().isEmpty) {
      return;
    }
    try {
      final notes = await _service.addNote(conversation.id, text.trim());
      _conversation = ChatConversation(
        id: conversation.id,
        customerId: conversation.customerId,
        customerName: conversation.customerName,
        lastMessage: conversation.lastMessage,
        lastMessageAt: conversation.lastMessageAt,
        unreadForStaff: conversation.unreadForStaff,
        unreadForCustomer: conversation.unreadForCustomer,
        notes: notes,
      );
      notifyListeners();
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      notifyListeners();
    }
  }

  void resetIfUserChanged(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _timer?.cancel();
      _timer = null;
      _conversation = null;
      _messages = const [];
      _staffConversations = const [];
      _botMessages.clear();
    }
  }

  void clear() {
    stopPolling();
    _conversation = null;
    _messages = const [];
    _staffConversations = const [];
    _botMessages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
