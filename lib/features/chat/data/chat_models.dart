import '../../product/data/models/product_model.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.productId,
    this.productName,
  });

  final String id;
  final String conversationId;
  final String senderId;

  /// `CUSTOMER`, `PHARMACIST` hoặc `ADMIN`.
  final String senderRole;
  final String senderName;
  final String content;
  final String createdAt;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? productId;
  final String? productName;

  bool get isFromStaff => senderRole != 'CUSTOMER';
  bool get hasImage => attachmentUrl != null && attachmentType == 'IMAGE';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) {
      final s = v?.toString();
      return s == null || s.isEmpty ? null : s;
    }

    return ChatMessage(
      id: json['id'].toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? 'CUSTOMER').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      attachmentUrl: text(json['attachmentUrl']),
      attachmentType: text(json['attachmentType']),
      productId: text(json['productId']),
      productName: text(json['productName']),
    );
  }
}

class ChatNote {
  const ChatNote({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String content;
  final String authorName;
  final String createdAt;

  factory ChatNote.fromJson(Map<String, dynamic> json) {
    return ChatNote(
      id: json['id'].toString(),
      content: (json['content'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadForStaff = 0,
    this.unreadForCustomer = 0,
    this.notes = const [],
  });

  final String id;
  final String customerId;
  final String customerName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadForStaff;
  final int unreadForCustomer;
  final List<ChatNote> notes;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final notes = json['notes'];
    return ChatConversation(
      id: json['id'].toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Khách hàng').toString(),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt']?.toString(),
      unreadForStaff: int.tryParse('${json['unreadForStaff'] ?? 0}') ?? 0,
      unreadForCustomer: int.tryParse('${json['unreadForCustomer'] ?? 0}') ?? 0,
      notes: notes is List
          ? notes
                .map(
                  (e) => ChatNote.fromJson(
                    e is Map
                        ? e.map((k, v) => MapEntry(k.toString(), v))
                        : <String, dynamic>{'id': ''},
                  ),
                )
                .toList()
          : const [],
    );
  }
}

/// Một tin nhắn trong khung chat với trợ lý tự động (chỉ lưu trên máy).
class BotMessage {
  const BotMessage({
    required this.fromBot,
    required this.text,
    this.products = const [],
    this.suggestions = const [],
  });

  final bool fromBot;
  final String text;
  final List<ProductModel> products;
  final List<String> suggestions;
}
