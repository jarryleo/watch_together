import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:watch_together/route/route_ext.dart';
import 'package:watch_together/route/routes.dart';

class JoinLogic extends GetxController {
  var isLoading = false.obs;
  var isError = false.obs;
  TextEditingController roomIdController = TextEditingController();
  late MainService mainService;

  @override
  void onInit() {
    super.onInit();
    mainService = Get.find<MainService>();
    roomIdController.addListener(() {
      isError.value = false;
    });
  }

  void joinRoom() {
    var roomId = roomIdController.text;
    if (roomId.length != 6) {
      isError.value = true;
      return;
    }
    isLoading.value = true;
    mainService.join(roomId).then((value) {
      isLoading.value = false;
      if (value) {
        Routes.main.pagePush();
      } else {
        SmartDialog.showToast("连接服务器失败");
      }
    });
  }
}
