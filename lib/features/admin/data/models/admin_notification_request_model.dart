class AdminNotificationRequestModel {
  const AdminNotificationRequestModel({
    required this.sendToAllCustomers,
    required this.title,
    required this.content,
    required this.type,
    this.userId,
    this.referenceId,
  });

  final String? userId;
  final bool sendToAllCustomers;
  final String title;
  final String content;
  final String type;
  final String? referenceId;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sendToAllCustomers': sendToAllCustomers,
      'title': title,
      'content': content,
      'type': type,
      'referenceId': referenceId,
    };
  }
}
