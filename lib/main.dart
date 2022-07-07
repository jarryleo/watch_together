import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/dlna/desktop_video_page.dart';

import 'dlna/phone_video_page.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    await DartVLC.initialize(useFlutterNativeView: true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Dlna',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Platform.isAndroid || Platform.isIOS
            ? const PhoneVideoPage(
                title: 'Flutter Dlna demo',
              )
            : Platform.isWindows || Platform.isLinux
                ? const DesktopVideoPage(title: 'Flutter Dlna demo')
                : const Center(child: Text("该设备不支持！")));
  }
}
