import 'package:fijkplayer/fijkplayer.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/main/main_logic.dart';

class PhoneVideoLogic extends MainLogic {
  final FijkPlayer player = FijkPlayer();

  @override
  void onInit() {
    super.onInit();
    player.addListener(_playerValueChanged);
    player.onCurrentPosUpdate.listen((pos) {
      RoomInfo.playerInfo.position = pos.inSeconds;
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    player.release();
    player.dispose();
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
      player.pause();
    }
  }

  @override
  void play() {
    super.play();
    player.start();
  }

  @override
  void seek(int position) {
    super.seek(position);
    player.seekTo(position * 1000);
  }

  @override
  void setUrl(String url) {
    if (url == RoomInfo.playerInfo.url) return;
    super.setUrl(url);
    player.setDataSource(url, autoPlay: true);
  }

  @override
  void stop() {
    super.stop();
    player.stop();
    player.reset();
  }

  //播放器状态监听(同步房间其他人)
  void _playerValueChanged() {
    FijkValue value = player.value;
    bool playing = (value.state == FijkState.started);
    if (playing != RoomInfo.playerInfo.isPlaying) {
      //播放暂停控制
      if (playing) {
        play();
        Wakelock.enable();
      } else {
        pause();
        Wakelock.disable();
      }
      RoomInfo.playerInfo.isPlaying = playing;
    }
    if (value.state == FijkState.prepared) {
      sync();
    }
  }
}
