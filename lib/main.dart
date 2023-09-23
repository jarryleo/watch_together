import 'package:flutter/material.dart';
import 'package:watch_together/config_device.dart';
import 'package:watch_together/route/router_helper.dart';
import 'package:watch_together/utils/platform_utils.dart';

import 'config_window.dart';

void main() async {
  await ConfigDevice.init();
  if (PlatFormUtils.isDesktop()) {
    await ConfigWindow.init();
  }
  runApp(RouterHelper.init());
}
