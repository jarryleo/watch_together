import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:window_manager/window_manager.dart';

import 'includes.dart';

class Config {
  ///初始化
  static Future<void> init() async {
    //初始化存储
    await GetStorage.init();
    //初始化vlc
    if (Platform.isWindows || Platform.isLinux) {
      DartVLC.initialize();
    }
    //初始化窗口
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await initWindow();
    }
    //初始化服务
    await Get.putAsync(() => MainService().init());
  }

  ///初始化窗口设置
  static Future<void> initWindow() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(800, 600),
      center: true,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
