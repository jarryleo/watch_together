import 'package:dart_vlc/dart_vlc.dart';
import 'package:window_manager/window_manager.dart';

import 'includes.dart';

class ConfigWindow {
  ///初始化
  static Future<void> init() async {
    //初始化vlc
    await DartVLC.initialize(useFlutterNativeView: true);
    //初始化窗口
    await initWindow();
  }

  ///初始化窗口设置
  static Future<void> initWindow() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(360, 240),
      center: true,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
