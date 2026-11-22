import 'package:flutter/foundation.dart';

import '../../../core/network/json_api.dart';
import '../data/support_models.dart';

class SupportProvider extends ChangeNotifier {
  SupportProvider({JsonApi? api}) : _api = api ?? JsonApi();

  final JsonApi _api;

  String? _userId;
  List<Faq> _faqs = const [];
  SupportInfo? _info;
  List<SupportTicket> _tickets = const [];
  SupportTicket? _selected;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Faq> get faqs => _faqs;
  SupportInfo? get info => _info;
  List<SupportTicket> get tickets => _tickets;
  SupportTicket? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void resetIfUserChanged(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _tickets = const [];
      _selected = null;
    }
  }

  Future<void> loadHelpCenter() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _faqs = JsonApi.asList(await _api.get('/support/faqs'))
          .map(Faq.fromJson)
          .toList();
      _info = SupportInfo.fromJson(
        JsonApi.asMap(await _api.get('/support/info')),
      );
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyTickets() => _loadTickets('/support/tickets');

  Future<void> loadStaffTickets({String? status}) {
    return _loadTickets(
      '/support/staff/tickets',
      query: status == null ? null : {'status': status},
    );
  }

  Future<void> _loadTickets(String path, {Map<String, dynamic>? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _tickets = JsonApi.asList(await _api.get(path, query: query))
          .map(SupportTicket.fromJson)
          .toList();
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTicket(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selected = SupportTicket.fromJson(
        JsonApi.asMap(await _api.get('/support/tickets/$id')),
      );
    } catch (error) {
      _errorMessage = JsonApi.message(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket({
    required String category,
    required String subject,
    required String content,
    String? orderId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.post(
        '/support/tickets',
        body: {
          'category': category,
          'subject': subject,
          'content': content,
          if (orderId != null) 'orderId': orderId,
        },
      );
      return true;
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> reply(String ticketId, String content) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selected = SupportTicket.fromJson(
        JsonApi.asMap(
          await _api.post(
            '/support/tickets/$ticketId/messages',
            body: {'content': content},
          ),
        ),
      );
      return true;
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Nhân viên cập nhật trạng thái và (tùy chọn) phản hồi khách.
  Future<bool> staffUpdate(
    String ticketId, {
    required String status,
    String reply = '',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _selected = SupportTicket.fromJson(
        JsonApi.asMap(
          await _api.put(
            '/support/staff/tickets/$ticketId',
            body: {'status': status, 'reply': reply},
          ),
        ),
      );
      return true;
    } catch (error) {
      _errorMessage = JsonApi.message(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
