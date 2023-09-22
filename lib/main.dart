import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/config.dart';
import 'package:watch_together/route/router_helper.dart';

import 'config_window.dart';

void main() async {
  await Config.init();
  await ConfigWindow.init();
  runApp(RouterHelper.init());
}
