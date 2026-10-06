import 'package:flutter/services.dart';

class PlatformService {
  static const platform = MethodChannel('vn.edu.vku/device_info');

  /// Calls native Android (Kotlin) / iOS (Swift) via MethodChannel
  /// As specified in Slide 37-39
  static Future<int> getBatteryLevel() async {
    try {
      final int? result = await platform.invokeMethod<int>('getBatteryLevel');
      return result ?? -1;
    } on PlatformException catch (_) {
      return -1;
    } catch (_) {
      return -1;
    }
  }
}
