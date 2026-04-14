import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const override =
        String.fromEnvironment('RIPO_API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8080';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8080';
    }
  }
}
