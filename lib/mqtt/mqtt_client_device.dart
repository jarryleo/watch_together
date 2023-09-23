import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:watch_together/mqtt/mqtt_client.dart';
import 'package:watch_together/mqtt/mqtt_config.dart';
import 'package:watch_together/utils/client_id_util.dart';

class MqttClientDevice extends XMqttClient {
  @override
  Future<MqttClient> buildClient() async {
    MqttServerClient client = MqttServerClient.withPort(
        MqttConfig.host, ClientIdUtil.getClientId(), MqttConfig.port);
    var defaultContext = SecurityContext.defaultContext;
    var certBytes = await rootBundle.load(MqttConfig.crtFile);
    defaultContext.setTrustedCertificatesBytes(certBytes.buffer.asInt8List());
    client.securityContext = defaultContext;
    client.secure = true;
    return client;
  }
}
