import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/main/main_logic.dart';

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
    customVideoPlayerController = CustomVideoPlayerController(
      context: Get.context!,
      videoPlayerController: videoPlayerController!,
    );
  }

  void _switchVideoSource(String source) async {
    await videoPlayerController?.pause();
    videoPlayerController?.removeListener(_videoListener);
    await videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.network(source);
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
    //视频加载完成
    if (videoPlayerController?.value.isInitialized ?? false) {
      if (!RoomInfo.isOwner) {
        if (RoomInfo.playerInfo.isPlaying) {
          videoPlayerController?.play();
          Wakelock.enable();
        } else {
          videoPlayerController?.pause();
          Wakelock.disable();
        }
        //同步进度
        seek(RoomInfo.playerInfo.position);
      } else {
        //房主播放器准备完成，同步房间其他人
        play();
      }
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
