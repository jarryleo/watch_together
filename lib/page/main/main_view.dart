import 'dart:io';

import 'package:flutter/material.dart';
import 'package:watch_together/page/video/desktop/desktop_video_page.dart';
import 'package:watch_together/page/video/phone/phone_video_page.dart';


class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return const PhoneVideoPage();
    } else {
      return const DesktopVideoPage();
    }
  }
}