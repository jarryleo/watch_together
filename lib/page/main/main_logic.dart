import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:watch_together/dialog/dialog_input_video_url.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/ext/string_ext.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/page/main/main_service.dart';

import '../../includes.dart';

abstract class MainLogic extends GetxController implements PlayerAction {
  final MainService mainService = Get.find<MainService>();
  final TextEditingController urlController = TextEditingController();
  var isRoomOwner = false.obs;
  StreamSubscription<bool>? roomOwnerSub;
  StreamSubscription<String>? danmakuSub;

  @override
  void onInit() {
    super.onInit();
    mainService.setPlayerInfoCallback(this);
    roomOwnerSub = mainService.getRoomOwnerStream().listen(onRoomOwnerChanged);
    danmakuSub = mainService.getDanmakuStream().listen(onDanmakuArrived);
  }

  @override
  void onClose() {
    super.onClose();
    mainService.setPlayerInfoCallback(null);
  }

  void onRoomOwnerChanged(bool isRoomOwner) {
    this.isRoomOwner.value = isRoomOwner;
    if (isRoomOwner) {
      QLog.d("start dlna server");
      "您已成为房主，可以进行投屏/设置播放地址等操作".showSnackBar();
    } else {
      QLog.d("stop dlna server");
    }
  }

  ///收到房主的弹幕消息，子类实现
  void onDanmakuArrived(String danmakuText);

  ///退出房间
  void exitRoom() {
    mainService.exit();
    roomOwnerSub?.cancel();
    danmakuSub?.cancel();
    roomOwnerSub = null;
    danmakuSub = null;
  }

  void sync() {
    if (RoomInfo.isOwner) {
      "您是房主，无需同步".showSnackBar();
    } else {
      "正在同步房主的播放进度".showSnackBar();
      mainService.sync();
    }
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
    mainService.setUrl(url);
  }

  @mustCallSuper
  @override
  void stop() {
    RoomInfo.playerInfo.url = "";
    RoomInfo.playerInfo.isPlaying = false;
  }

  ///发送弹幕
  void sendDanmaku(String danmakuText) {
    mainService.sendDanmaku(danmakuText);
  }

  void showInputUrlDialog() {
    SmartDialog.show(
      builder: (context) {
        return InputVideoUrlDialog(
          onInputUrlCallback: (value) {
            setUrl(value);
          },
        );
      },
    );
  }

  void inputUrl() {
    setUrl(urlController.text);
  }
}
