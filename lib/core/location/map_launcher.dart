import 'package:url_launcher/url_launcher.dart';

/// Mở ứng dụng bản đồ chỉ đường / ứng dụng gọi điện bằng `url_launcher`.
class MapLauncher {
  const MapLauncher._();

  /// Mở Google Maps chỉ đường tới tọa độ hoặc địa chỉ. Trả về `false` nếu không mở được.
  static Future<bool> openDirections({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final String destination;
    if (latitude != null && longitude != null) {
      destination = '$latitude,$longitude';
    } else if (address != null && address.trim().isNotEmpty) {
      destination = address.trim();
    } else {
      return false;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> call(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      return false;
    }
    try {
      return await launchUrl(Uri(scheme: 'tel', path: digits));
    } catch (_) {
      return false;
    }
  }
}
