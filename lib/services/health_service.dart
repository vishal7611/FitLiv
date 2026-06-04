import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  final Health _health = Health();

  static final List<HealthDataType> types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
  ];

  static final List<HealthDataAccess> permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> requestPermissions() async {
    // Request Android permissions first
    await Permission.sensors.request();
    
    // Request Health Connect/Google Fit permissions
    bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
    
    if (hasPermissions != true) {
      try {
        return await _health.requestAuthorization(types, permissions: permissions);
      } catch (e) {
        print("Error requesting health permissions: $e");
        return false;
      }
    }
    return true;
  }

  Future<Map<String, int?>> fetchLatestMetrics() async {
    DateTime now = DateTime.now();
    DateTime fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: fiveMinutesAgo,
        endTime: now,
      );

      int? heartRate;
      int? bloodOxygen;

      for (var point in healthData) {
        if (point.type == HealthDataType.HEART_RATE) {
          heartRate = (point.value as NumericHealthValue).numericValue.toInt();
        } else if (point.type == HealthDataType.BLOOD_OXYGEN) {
          // Blood oxygen is often represented as a percentage (e.g., 0.98 for 98%)
          double value = (point.value as NumericHealthValue).numericValue.toDouble();
          bloodOxygen = value < 1.0 ? (value * 100).toInt() : value.toInt();
        }
      }

      return {
        'heartRate': heartRate,
        'bloodOxygen': bloodOxygen,
      };
    } catch (e) {
      print("Error fetching health data: $e");
      return {
        'heartRate': null,
        'bloodOxygen': null,
      };
    }
  }
}
