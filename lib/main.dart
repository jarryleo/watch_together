import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/remote/remote.dart';
import 'package:watch_together/video/desktop_video_page.dart';

import 'video/phone_video_page.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    await DartVLC.initialize(useFlutterNativeView: true);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  //创建远程管理类
  Remote remote = Remote();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Watch together',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Platform.isAndroid || Platform.isIOS
            ? PhoneVideoPage(remote, title: 'Watch together')
            : Platform.isWindows || Platform.isLinux
                ? DesktopVideoPage(remote, title: 'Watch together')
                : const Center(child: Text("该设备不支持！")));
  }
}
