import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/route/router_helper.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    await DartVLC.initialize(useFlutterNativeView: true);
  }
  runApp(RouterHelper.init());
}
