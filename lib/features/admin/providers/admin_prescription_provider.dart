import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../prescription/data/models/prescription_model.dart';
import '../data/services/admin_prescription_service.dart';

class AdminPrescriptionProvider extends ChangeNotifier {
  AdminPrescriptionProvider({
    AdminPrescriptionService? adminPrescriptionService,
  }) : _adminPrescriptionService =
           adminPrescriptionService ?? AdminPrescriptionService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AdminPrescriptionService _adminPrescriptionService;

  List<PrescriptionModel> _prescriptions = const [];
  bool _isLoading = false;
  bool _isReviewing = false;
  String? _errorMessage;
  String? _selectedStatus;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  bool get isReviewing => _isReviewing;
  String? get errorMessage => _errorMessage;
  String? get selectedStatus => _selectedStatus;

  Future<void> loadPrescriptions({String? status}) async {
    _selectedStatus = status;
    _setLoading(true);

    try {
      final page = await _adminPrescriptionService.getPrescriptions(
        status: _selectedStatus,
      );
      _prescriptions = page.content;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> reviewPrescription({
    required String id,
    required String status,
    String? pharmacistNote,
  }) async {
    _setReviewing(true);

    try {
      await _adminPrescriptionService.reviewPrescription(
        id: id,
        status: status,
        pharmacistNote: pharmacistNote,
      );
      await loadPrescriptions(status: _selectedStatus);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setReviewing(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setReviewing(bool value) {
    if (_isReviewing == value) return;
    _isReviewing = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
