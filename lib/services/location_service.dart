import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.speedKmh,
  });

  final double lat;
  final double lng;
  final double speedKmh;
}

class LocationService {
  Future<LocationFix?> current() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return null;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final asked = await Geolocator.requestPermission();
      if (asked == LocationPermission.denied ||
          asked == LocationPermission.deniedForever) {
        return null;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final speedMs = pos.speed.isNaN || pos.speed < 0 ? 0.0 : pos.speed;
    return LocationFix(
      lat: pos.latitude,
      lng: pos.longitude,
      speedKmh: speedMs * 3.6,
    );
  }

  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    if (lat1 == 0 && lng1 == 0) return 0;
    if (lat2 == 0 && lng2 == 0) return 0;
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }
}
