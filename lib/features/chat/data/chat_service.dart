import '../../../core/network/json_api.dart';
import '../../product/data/models/product_model.dart';
import 'chat_models.dart';

class ChatService {
  ChatService({JsonApi? api}) : _api = api ?? JsonApi();

  final JsonApi _api;

  Future<ChatConversation> myConversation() async {
    return ChatConversation.fromJson(
      JsonApi.asMap(await _api.get('/chat/my-conversation')),
    );
  }

  Future<List<ChatMessage>> messages(
    String conversationId, {
    String? after,
  }) async {
    final data = await _api.get(
      '/chat/conversations/$conversationId/messages',
      query: after == null ? null : {'after': after},
    );
    return JsonApi.asList(data).map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> send(
    String conversationId, {
    String content = '',
    String? attachmentUrl,
    String? attachmentType,
    String? productId,
  }) async {
    final data = await _api.post(
      '/chat/conversations/$conversationId/messages',
      body: {
        'content': content,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentType != null) 'attachmentType': attachmentType,
        if (productId != null) 'productId': productId,
      },
    );
    return ChatMessage.fromJson(JsonApi.asMap(data));
  }

  Future<void> markRead(String conversationId) async {
    await _api.put('/chat/conversations/$conversationId/read');
  }

  Future<bool> pharmacistOnline() async {
    final data = JsonApi.asMap(await _api.get('/chat/presence'));
    return data['pharmacistOnline'] == true;
  }

  Future<void> setPresence({required bool online}) async {
    await _api.put('/chat/presence', body: {'online': online});
  }

  Future<List<ChatConversation>> staffConversations() async {
    return JsonApi.asList(await _api.get('/chat/conversations'))
        .map(ChatConversation.fromJson)
        .toList();
  }

  Future<List<ChatNote>> addNote(String conversationId, String content) async {
    final data = await _api.post(
      '/chat/conversations/$conversationId/notes',
      body: {'content': content},
    );
    return JsonApi.asList(data).map(ChatNote.fromJson).toList();
  }

  Future<BotMessage> askBot(String message) async {
    final data = JsonApi.asMap(
      await _api.post('/chat/bot', body: {'message': message}),
    );
    final suggestions = data['suggestions'];
    return BotMessage(
      fromBot: true,
      text: (data['reply'] ?? '').toString(),
      products: JsonApi.asList(data['products'])
          .map(ProductModel.fromJson)
          .toList(),
      suggestions: suggestions is List
          ? suggestions.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
