import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:watch_together/remote/room_owner_callback.dart';
import 'package:watch_together/route/router_helper.dart';

abstract class MainLogic extends GetxController
    implements PlayerAction, RoomOwnerCallback {
  final DlnaServer dlnaServer = DlnaServer(name: RouterHelper.appName);
  final MainService mainService = Get.find<MainService>();
  var isRoomOwner = false.obs;

  @override
  void onInit() {
    super.onInit();
    mainService.setPlayerInfoCallback(this);
    mainService.setRoomOwnerCallback(this);
  }

  @override
  void onRoomOwnerChanged(bool isRoomOwner) {
    this.isRoomOwner.value = isRoomOwner;
    if (isRoomOwner) {
      dlnaServer.start(this);
      QLog.d("start dlna server");
      Get.snackbar("提示", "已成为房主，可以投屏了");
    } else {
      dlnaServer.stop();
      QLog.d("stop dlna server");
    }
  }

  void exitRoom() {
    mainService.exit();
    dlnaServer.stop();
  }

  void sync() {
    mainService.sync();
  }

  @mustCallSuper
  @override
  void pause() {
    RoomInfo.playerInfo.isPlaying = false;
    mainService.pause();
  }

  @mustCallSuper
  @override
  void play() {
    RoomInfo.playerInfo.isPlaying = true;
    mainService.play();
  }

  @mustCallSuper
  @override
  void seek(int position) {
    RoomInfo.playerInfo.position = position;
    mainService.seek(position);
  }

  @mustCallSuper
  @override
  void setUrl(String url) {
    RoomInfo.playerInfo.url = url;
  }

  @mustCallSuper
  @override
  void stop() {
    RoomInfo.playerInfo.url = "";
    RoomInfo.playerInfo.isPlaying = false;
  }
}
