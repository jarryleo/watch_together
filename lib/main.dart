import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/video/desktop_video_page.dart';

import 'video/phone_video_page.dart';

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
        title: 'Watch together',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Platform.isAndroid || Platform.isIOS
            ? const PhoneVideoPage(title: 'Watch together')
            : Platform.isWindows || Platform.isLinux
                ? const DesktopVideoPage(title: 'Watch together')
                : const Center(child: Text("该设备不支持！")));
  }
}
