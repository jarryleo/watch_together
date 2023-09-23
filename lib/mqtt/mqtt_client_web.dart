import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:watch_together/mqtt/mqtt_client.dart';
import 'package:watch_together/mqtt/mqtt_config.dart';
import 'package:watch_together/utils/client_id_util.dart';

class MqttClientWeb extends XMqttClient {
  @override
  Future<MqttClient> buildClient() async {
    return MqttBrowserClient.withPort(
        MqttConfig.hostWeb, ClientIdUtil.getClientId(), MqttConfig.portWeb);
  }
}
