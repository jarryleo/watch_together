import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:watch_together/mqtt/mqtt_config.dart';

class ClientIdUtil {
  static const String _keyClientId = 'key_client_id';

  /// Get client id from local storage, if not exist, generate one.
  static String getClientId() {
    GetStorage storage = GetStorage();
    String? clientId = storage.read(_keyClientId);
    if (clientId == null) {
      clientId = _generateClientId();
      storage.write(_keyClientId, clientId);
    }
    return clientId;
  }

  static String _getPlatformName() {
    return Platform.operatingSystem;
  }

  static String _getUuid() {
    Uuid uuid = const Uuid();
    return uuid.v4();
  }

  static String _generateClientId() {
    return "${MqttConfig.clientId}${_getPlatformName()}_${_getUuid()}";
  }
}