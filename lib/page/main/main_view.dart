import 'package:flutter/material.dart';
import 'package:watch_together/page/video/desktop/desktop_video_page.dart';
import 'package:watch_together/page/video/phone/phone_video_page.dart';
import 'package:watch_together/utils/platform_utils.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatFormUtils.isMobile()) {
      return const PhoneVideoPage();
    } else if (PlatFormUtils.isDesktop()) {
      return const DesktopVideoPage();
    } else {
      return const Center(
        child: Text('暂不支持该平台'),
      );
    }
  }
}
