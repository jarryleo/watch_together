import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/constants.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/page/main/main_logic.dart';

import '../../../includes.dart';

class DesktopVideoLogic extends MainLogic {
  Player player = Player(id: 511);
  MediaType mediaType = MediaType.file;
  CurrentState current = CurrentState();
  PositionState position = PositionState();
  PlaybackState playback = PlaybackState();
  GeneralState general = GeneralState();
  VideoDimensions videoDimensions = const VideoDimensions(0, 0);
  List<Media> medias = <Media>[];

  //List<Device> devices = <Device>[];
  TextEditingController controller = TextEditingController();
  TextEditingController metasController = TextEditingController();
  double bufferingProgress = 0.0;
  Media? metasMedia;

  final BarrageWallController barrageWallController = BarrageWallController();

  var isDanmakuInputShow = false.obs;
  bool prepared = false;

  @override
  void onInit() {
    super.onInit();
    player.setVolume(0.5);
    player.currentStream.listen((current) {
      this.current = current;
    });
    player.positionStream.listen((position) {
      var pos = position.position;
      if (pos != null) {
        //拖拽进度,绝对值大于5秒才同步
        if ((pos.inSeconds - RoomInfo.playerInfo.position).abs() >
            Constants.diffSec) {
          mainService.seek(pos.inSeconds);
        }
        RoomInfo.playerInfo.position = pos.inSeconds;
      }
    });
    player.playbackStream.listen((playback) {
      bool playing = playback.isPlaying;
      //第一次播放，算作初始化完成
      if (!prepared) {
        prepared = true;
        if (!RoomInfo.isOwner) {
          seek(RoomInfo.playerInfo.getFixPosition());
          if (RoomInfo.playerInfo.isPlaying) {
            player.play();
            Wakelock.enable();
          } else {
            player.pause();
            Wakelock.disable();
          }
          sync();
        }
        return;
      }
      //播放暂停控制
      if (playing) {
        super.play();
        Wakelock.enable();
      } else {
        super.pause();
        Wakelock.disable();
      }
      RoomInfo.playerInfo.isPlaying = playing;
    });
    player.generalStream.listen((general) {
      this.general = general;
    });
    player.videoDimensionsStream.listen((videoDimensions) {
      this.videoDimensions = videoDimensions;
    });
    player.bufferingProgressStream.listen(
      (bufferingProgress) {
        this.bufferingProgress = bufferingProgress;
      },
    );
    player.errorStream.listen((event) {
      QLog.e('libvlc error: $event', tag: 'DesktopVideoLogic');
    });
    //devices = Devices.all;
    Equalizer equalizer = Equalizer.createMode(EqualizerMode.live);
    equalizer.setPreAmp(10.0);
    equalizer.setBandAmp(31.25, 10.0);
    player.setEqualizer(equalizer);
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    player.dispose();
  }

  @override
  int getDuration() {
    //dlna need
    return player.position.duration?.inSeconds ?? 0;
  }

  @override
  int getPosition() {
    //dlna need
    return player.position.position?.inSeconds ?? 0;
  }

  @override
  int getVolume() {
    //dlna need
    return (player.general.volume * 100).toInt();
  }

  @override
  void pause() {
    super.pause();
    //dlna or mqtt call
    player.pause();
  }

  @override
  void play() {
    super.play();
    player.play();
  }

  @override
  void seek(int position) {
    super.seek(position);
    player.seek(Duration(seconds: position));
  }

  @override
  void setUrl(String url) {
    if (url == RoomInfo.playerInfo.url) return;
    super.setUrl(url);
    prepared = false;
    var media = Media.network(url);
    player.open(media);
  }

  @override
  void stop() {
    super.stop();
    player.stop();
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
