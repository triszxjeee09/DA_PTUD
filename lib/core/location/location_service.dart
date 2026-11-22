import 'package:geolocator/geolocator.dart';

/// Kết quả lấy vị trí hiện tại.
class LocationResult {
  const LocationResult({this.latitude, this.longitude, this.message});

  final double? latitude;
  final double? longitude;
  final String? message;

  bool get hasPosition => latitude != null && longitude != null;
}

class LocationService {
  const LocationService();

  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(message: 'Vui lòng bật dịch vụ định vị (GPS)');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          message: 'Ứng dụng chưa được cấp quyền vị trí',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(message: 'Không thể xác định vị trí hiện tại');
    }
  }

  /// Khoảng cách theo mét giữa hai tọa độ.
  double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
