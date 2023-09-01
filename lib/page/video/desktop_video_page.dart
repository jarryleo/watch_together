import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/main/main_logic.dart';
import 'package:watch_together/remote/remote.dart';

class DesktopVideoPage extends StatefulWidget {
  const DesktopVideoPage({super.key});

  @override
  State<DesktopVideoPage> createState() => _DesktopVideoPageState();
}

class _DesktopVideoPageState extends State<DesktopVideoPage>
    implements PlayerAction {

  final MainLogic mainLogic = Get.find<MainLogic>();
  //当前播放的url
  var currentUrl = "";

  //播放状态
  bool _playing = false;
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

  @override
  void initState() {
    super.initState();
    if (mounted) {
      player.currentStream.listen((current) {
        setState(() => this.current = current);
      });
      player.positionStream.listen((position) {
        setState(() => this.position = position);
        var pos = position.position;
        if (pos != null) {
          RoomInfo.playerInfo.position = pos.inSeconds;
        }
      });
      player.playbackStream.listen((playback) {
        setState(() => this.playback = playback);
        if (_playing != playback.isPlaying) {
          if (playback.isPlaying) {
            //remote.play();
            Wakelock.enable();
          } else {
            //remote.pause();
            Wakelock.disable();
          }
        }
        _playing = playback.isPlaying;
      });
      player.generalStream.listen((general) {
        setState(() => this.general = general);
      });
      player.videoDimensionsStream.listen((videoDimensions) {
        setState(() => this.videoDimensions = videoDimensions);
      });
      player.bufferingProgressStream.listen(
        (bufferingProgress) {
          setState(() => this.bufferingProgress = bufferingProgress);
        },
      );
      player.errorStream.listen((event) {
        if (kDebugMode) {
          print('libvlc error.');
        }
      });
      //devices = Devices.all;
      Equalizer equalizer = Equalizer.createMode(EqualizerMode.live);
      equalizer.setPreAmp(10.0);
      equalizer.setBandAmp(31.25, 10.0);
      player.setEqualizer(equalizer);
    }
    /*if (!remote.isRoomOwner) {
      _sync();
    }*/
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    player.dispose();
    // dlnaServer.stop();
    // remote.exit();
    // remote.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("房间号：${RoomInfo.roomId}(${RoomInfo.isOwner ? "房主" : "观众"})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'sync',
            onPressed: _sync,
          ),
        ],
      ),
      body: Video(
        player: player,
        volumeThumbColor: Colors.blue,
        volumeActiveColor: Colors.blue,
      ),
    );
  }

  void _sync() {
    //remote.syncRemote();
  }

  @override
  int getPosition() {
    return player.position.position?.inSeconds ?? 0;
  }

  @override
  int getDuration() {
    return player.position.duration?.inSeconds ?? 0;
  }

  @override
  int getVolume() {
    return (player.general.volume * 100).toInt();
  }

  @override
  void pause() {
    player.pause();
  }

  @override
  void play() {
    player.play();
  }

  @override
  void seek(int position) {
    player.seek(Duration(seconds: position));
  }

  @override
  void setUrl(String url) {
    if (url == currentUrl) return;
    currentUrl = url;
    var media = Media.network(url);
    player.open(media);
    //remote.setUrl(url);
  }

  @override
  void stop() {
    currentUrl = "";
    player.stop();
  }
}
