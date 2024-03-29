import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/constants.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/main/main_logic.dart';
import 'package:watch_together/route/route_ext.dart';
import 'package:watch_together/route/routes.dart';

import '../../../includes.dart';

class WebLogic extends MainLogic {
  VideoPlayerController? videoPlayerController;
  CustomVideoPlayerController? customVideoPlayerController;

  //弹幕控制器
  final BarrageWallController barrageWallController = BarrageWallController();
  var isDanmakuInputShow = false.obs;

  @override
  void onInit() {
    super.onInit();
    videoPlayerController = VideoPlayerController.network("");
    videoPlayerController?.addListener(_videoListener);
    customVideoPlayerController = CustomVideoPlayerController(
      context: Get.context!,
      videoPlayerController: videoPlayerController!,
    );
  }

  @override
  void onReady() {
    super.onReady();
    //浏览器刷新跳转房间号输入页面
    if (RoomInfo.roomId.length < 6) {
      Routes.root.pageOffAll();
    }
  }

  void _switchVideoSource(String source) async {
    await videoPlayerController?.pause();
    videoPlayerController?.removeListener(_videoListener);
    await videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.network(source);
    videoPlayerController?.addListener(_videoListener);
    customVideoPlayerController = CustomVideoPlayerController(
      context: Get.context!,
      videoPlayerController: videoPlayerController!,
    );
    await videoPlayerController?.initialize();
    await videoPlayerController
        ?.seekTo(Duration(seconds: RoomInfo.playerInfo.position));
    await videoPlayerController?.play();
    update();
  }

  void _videoListener() {
    if (RoomInfo.isOwner) {
      var pos = getPosition();
      //房主才记录拖拽进度,绝对值大于3秒才同步给其他人
      if ((pos - RoomInfo.playerInfo.position).abs() > Constants.diffSec) {
        mainService.seek(pos);
      }
      RoomInfo.playerInfo.position = pos;
    }
    bool playing = videoPlayerController?.value.isPlaying ?? false;
    if (playing != RoomInfo.playerInfo.isPlaying) {
      //播放暂停控制
      if (playing) {
        super.play();
        Wakelock.enable();
      } else {
        super.pause();
        Wakelock.disable();
      }
      RoomInfo.playerInfo.isPlaying = playing;
    }
  }

  @override
  void exitRoom() {
    videoPlayerController?.dispose();
    super.exitRoom();
  }

  @override
  int getDuration() {
    return videoPlayerController?.value.duration.inSeconds ?? 0;
  }

  @override
  int getPosition() {
    return videoPlayerController?.value.position.inSeconds ?? 0;
  }

  @override
  int getVolume() {
    return videoPlayerController?.value.volume.round() ?? 0;
  }

  @override
  void pause() {
    super.pause();
    videoPlayerController?.pause();
  }

  @override
  void play() {
    super.play();
    videoPlayerController?.play();
  }

  @override
  void seek(int position) {
    super.seek(position);
    videoPlayerController?.seekTo(Duration(seconds: position));
  }

  @override
  void setUrl(String url) {
    if (url == RoomInfo.playerInfo.url) return;
    super.setUrl(url);
    RoomInfo.playerInfo.isPlaying = true;
    _switchVideoSource(url);
  }

  @override
  void stop() {
    super.stop();
    videoPlayerController?.dispose();
  }

  @override
  void onDanmakuArrived(String danmakuText) {
    _addDanmaku(danmakuText);
  }

  ///屏幕展示弹幕
  void _addDanmaku(String message) {
    barrageWallController.send([
      Bullet(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ]);
  }
}
