import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/constants.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/page/main/main_ext.dart';
import 'package:watch_together/page/main/main_logic.dart';
import 'package:watch_together/utils/task_queue_utils.dart';

import '../../../includes.dart';

class PhoneVideoLogic extends MainLogic with DlnaOnMainLogic {
  final FijkPlayer player = FijkPlayer();
  final BarrageWallController barrageWallController = BarrageWallController();
  final TaskQueueUtils taskQueueUtils = TaskQueueUtils();

  @override
  void onInit() {
    super.onInit();
    player.addListener(_playerValueChanged);
    player.onCurrentPosUpdate.listen((pos) {
      if (!RoomInfo.isOwner) return;
      //房主拖拽进度,绝对值大于3秒才同步
      if ((pos.inSeconds - RoomInfo.playerInfo.position).abs() >
          Constants.diffSec) {
        mainService.seek(pos.inSeconds);
      }
      RoomInfo.playerInfo.position = pos.inSeconds;
    });
  }

  @override
  Future<void> onClose() async {
    super.onClose();
    await player.stop();
    await player.release();
    QLog.i("PhoneVideoLogic : onClose");
  }

  void _addTask(Future future) {
    taskQueueUtils.addTask(() {
      return future;
    });
  }

  @override
  int getDuration() {
    //dlna need
    return player.value.duration.inSeconds;
  }

  @override
  int getPosition() {
    //dlna need
    return player.currentPos.inSeconds;
  }

  @override
  int getVolume() {
    //dlna need
    return 0;
  }

  @override
  void pause() {
    super.pause();
    //dlna or mqtt call
    if (player.isPlayable()) {
      //player.pause();
      _addTask(player.pause());
    }
  }

  @override
  void play() {
    super.play();
    //player.start();
    _addTask(player.start());
  }

  @override
  void seek(int position) {
    super.seek(position);
    //player.seekTo(position * 1000);
    _addTask(player.seekTo(position * 1000));
  }

  @override
  void setUrl(String url) {
    if (url == RoomInfo.playerInfo.url) return;
    super.setUrl(url);
    RoomInfo.playerInfo.isPlaying = true;
    //player.reset();
    //player.setDataSource(url, autoPlay: true);
    _addTask(player.reset());
    _addTask(player.setDataSource(url, autoPlay: true));
  }

  @override
  void stop() {
    super.stop();
    //player.stop();
    //player.reset();
    _addTask(player.stop());
    _addTask(player.reset());
  }

  //播放器状态监听(同步房间其他人)
  void _playerValueChanged() {
    FijkValue value = player.value;
    bool playing = (value.state == FijkState.started);
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
    if (value.state == FijkState.prepared) {
      if (!RoomInfo.isOwner) {
        if (RoomInfo.playerInfo.isPlaying) {
          //player.start();
          _addTask(player.start());
          Wakelock.enable();
        } else {
          //player.pause();
          _addTask(player.pause());
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
