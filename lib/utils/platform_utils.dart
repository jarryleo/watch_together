import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:watch_together/mqtt/mqtt_client.dart';

class PlatFormUtils {
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool isWeb() {
    return kIsWeb ? true : false;
  }

  ///由不同平台初始化赋值，不依赖具体平台的包，避免报错
  static XMqttClient? mqttClient;
}
