import 'package:get_storage/get_storage.dart';
import 'package:watch_together/mqtt/mqtt_client_device.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:watch_together/utils/platform_utils.dart';

import 'includes.dart';

class ConfigDevice {
  ///初始化
  static Future<void> init() async {
    //初始化mqtt
    PlatFormUtils.mqttClient = MqttClientDevice();
    //初始化存储
    await GetStorage.init();
    //初始化服务
    await Get.putAsync(() => MainService().init());
  }
}
