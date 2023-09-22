import 'package:flutter/material.dart';
import 'package:watch_together/config.dart';
import 'package:watch_together/route/router_web.dart';

void main() async {
  await Config.init();
  runApp(RouterWeb.init());
}
