import 'package:flutter/material.dart';
import 'package:watch_together/route/router_web.dart';

import 'config_web.dart';

void main() async {
  await ConfigWeb.init();
  runApp(RouterWeb.init());
}
