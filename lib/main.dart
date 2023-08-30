import 'package:flutter/material.dart';
import 'package:watch_together/config.dart';
import 'package:watch_together/route/router_helper.dart';

void main() async {
  await Config.init();
  runApp(RouterHelper.init());
}
