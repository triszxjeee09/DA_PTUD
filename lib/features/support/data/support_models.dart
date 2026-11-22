class Faq {
  const Faq({required this.id, required this.question, required this.answer});

  final String id;
  final String question;
  final String answer;

  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id'].toString(),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
    );
  }
}

class SupportInfo {
  const SupportInfo({
    required this.hotline,
    required this.email,
    required this.workingHours,
  });

  final String hotline;
  final String email;
  final String workingHours;

  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    return SupportInfo(
      hotline: (json['hotline'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      workingHours: (json['workingHours'] ?? '').toString(),
    );
  }
}

class TicketMessage {
  const TicketMessage({
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  final String senderRole;
  final String senderName;
  final String content;
  final String createdAt;

  bool get isStaff => senderRole == 'STAFF';

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      senderRole: (json['senderRole'] ?? 'CUSTOMER').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.code,
    required this.category,
    required this.subject,
    required this.status,
    required this.statusLabel,
    required this.userName,
    required this.updatedAt,
    required this.messages,
  });

  static const Map<String, String> categoryLabels = {
    'COMPLAINT': 'Khiếu nại',
    'FEEDBACK': 'Góp ý',
    'ORDER': 'Vấn đề đơn hàng',
    'OTHER': 'Khác',
  };

  static const Map<String, String> statusLabels = {
    'OPEN': 'Đang chờ xử lý',
    'IN_PROGRESS': 'Đang xử lý',
    'RESOLVED': 'Đã giải quyết',
    'CLOSED': 'Đã đóng',
  };

  final String id;
  final String code;
  final String category;
  final String subject;
  final String status;
  final String statusLabel;
  final String userName;
  final String updatedAt;
  final List<TicketMessage> messages;

  String get categoryLabel => categoryLabels[category] ?? 'Khác';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'];
    return SupportTicket(
      id: json['id'].toString(),
      code: (json['code'] ?? '').toString(),
      category: (json['category'] ?? 'OTHER').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      messages: messages is List
          ? messages
                .map(
                  (e) => TicketMessage.fromJson(
                    e is Map
                        ? e.map((k, v) => MapEntry(k.toString(), v))
                        : <String, dynamic>{},
                  ),
                )
                .toList()
          : const [],
    );
  }
}
