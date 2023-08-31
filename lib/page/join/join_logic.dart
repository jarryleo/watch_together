import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:watch_together/route/route_ext.dart';
import 'package:watch_together/route/routes.dart';

class JoinLogic extends GetxController {
  var isLoading = false.obs;
  var errText = ''.obs;
  TextEditingController roomIdController = TextEditingController();
  late MainService mainService;

  @override
  void onInit() {
    super.onInit();
    mainService = Get.find<MainService>();
  }

  void joinRoom() {
    var roomId = roomIdController.text;
    if (roomId.isEmpty) {
      errText.value = '请输入房间号';
      return;
    }
    isLoading.value = true;
    mainService.join(roomId).then((value) {
      isLoading.value = false;
      if (value) {
        Routes.main.pageOffAll();
      } else {
        errText.value = '房间不存在';
      }
    });
  }
}
