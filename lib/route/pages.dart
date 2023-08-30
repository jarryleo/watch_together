import 'package:get/get.dart';
import 'package:watch_together/page/main/main_view.dart';

import 'routes.dart';

abstract class Pages {
  static final pages = [
    GetPage(name: Routes.root, page: () => const MainPage()),
  ];
}
