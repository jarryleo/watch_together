import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:watch_together/login.dart';
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

  String title = "Watch together";

  //创建远程管理类
  Remote remote = Remote();

  @override
  Widget build(BuildContext context) {
    return OKToast(child: app());
  }

  MaterialApp app() => MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:JoinPage(remote));
}
