
import 'package:watch_together/page/main/main_logic.dart';

import '../../includes.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainLogic>(() => MainLogic());
  }
}