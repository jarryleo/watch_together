import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/main/main_service.dart';
import 'package:watch_together/remote/room_owner_callback.dart';

abstract class MainLogic extends GetxController
    implements PlayerAction, RoomOwnerCallback {
  final DlnaServer dlnaServer = DlnaServer();
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
    } else {
      dlnaServer.stop();
    }
  }

  @override
  void dispose() {
    super.dispose();
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
