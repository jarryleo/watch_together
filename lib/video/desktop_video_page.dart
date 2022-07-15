import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dlna/dlna_flutter.dart';
import '../remote/remote.dart';

class DesktopVideoPage extends StatefulWidget {
  Remote remote;

  DesktopVideoPage(this.remote, {Key? key}) : super(key: key);

  @override
  State<DesktopVideoPage> createState() => _DesktopVideoPageState();
}

class _DesktopVideoPageState extends State<DesktopVideoPage>
    implements PlayerAction {
  DlnaServer dlnaServer = DlnaServer();
  late Remote remote;

  //当前播放的url
  var currentUrl = "";

  //播放状态
  bool _playing = false;
  Duration _currentPos = const Duration();

  Player player = Player(id: 511, registerTexture: !Platform.isWindows);
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
    remote = widget.remote;
    remote.setActionCallback(this);
    dlnaServer.start(this);
    if (mounted) {
      player.currentStream.listen((current) {
        setState(() => this.current = current);
      });
      player.positionStream.listen((position) {
        setState(() => this.position = position);
        var pos = position.position;
        if (pos != null) {
          //如果本地进度和播放器进度误差超过5s，则同步进度
          if ((pos.inSeconds - _currentPos.inSeconds).abs() >= 5) {
            remote.seek(pos.inSeconds);
          }
          _currentPos = pos;
        }
      });
      player.playbackStream.listen((playback) {
        setState(() => this.playback = playback);
        if (_playing != playback.isPlaying) {
          if (playback.isPlaying) {
            remote.play();
          } else {
            remote.pause();
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
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    dlnaServer.stop();
    remote.exit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text("房间号：${remote.roomId}(${remote.isRoomOwner ? "房主" : "观众"})"),
      ),
      body: Container(
          child: Platform.isWindows
              ? NativeVideo(
                  player: player,
                  volumeThumbColor: Colors.blue,
                  volumeActiveColor: Colors.blue,
                )
              : Video(
                  player: player,
                  volumeThumbColor: Colors.blue,
                  volumeActiveColor: Colors.blue,
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _sync,
        child: const Icon(Icons.sync),
      ),
    );
  }

  void _sync() {
    remote.syncRemote();
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
    var media = Media.network(url);
    player.open(media);
    remote.setUrl(url);
  }

  @override
  void stop() {
    currentUrl = "";
    player.stop();
  }
}
