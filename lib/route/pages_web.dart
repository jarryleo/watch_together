import 'package:get/get.dart';
import 'package:watch_together/page/join/join_view.dart';
import 'package:watch_together/page/video/web/web_view.dart';

import 'routes.dart';

abstract class PagesWeb {
  static final pages = [
    GetPage(name: Routes.root, page: () => const JoinPage()),
    GetPage(
      name: Routes.main,
      page: () => const WebPage(),
    ),
  ];
}
