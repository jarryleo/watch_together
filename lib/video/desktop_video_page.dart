import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../dlna/dlna_flutter.dart';
import '../remote/remote.dart';



class DesktopVideoPage extends StatefulWidget {

  Remote remote;

  DesktopVideoPage(this.remote,{Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DesktopVideoPage> createState() => _DesktopVideoPageState();
}

class _DesktopVideoPageState extends State<DesktopVideoPage> implements PlayerAction {
  DlnaServer dlnaServer = DlnaServer();
  late Remote remote;
  Player player = Player(
    id: 0,
    videoDimensions: const VideoDimensions(640, 360),
    registerTexture: !Platform.isWindows,
  );
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
    remote.setCallback(this);
    remote.join("527511");
    dlnaServer.start(this);
    if (mounted) {
      player.currentStream.listen((current) {
        setState(() => this.current = current);
      });
      player.positionStream.listen((position) {
        setState(() => this.position = position);
        remote.seek(position.position?.inSeconds??0);
      });
      player.playbackStream.listen((playback) {
        setState(() => this.playback = playback);
        if(playback.isPlaying){
          remote.play();
        }else{
          remote.pause();
        }
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
        print('libvlc error.');
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
    remote.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(child: Platform.isWindows
            ? NativeVideo(
          player: player,
          width: 640,
          height: 360,
          volumeThumbColor: Colors.blue,
          volumeActiveColor: Colors.blue,
          showControls: true,
        )
            : Video(
          player: player,
          width: 640,
          height: 360,
          volumeThumbColor: Colors.blue,
          volumeActiveColor: Colors.blue,
          showControls: true,
        )));
  }

  @override
  int getPosition() {
    return player.position.position?.inSeconds??0;
  }

  @override
  int getDuration() {
    return player.position.duration?.inSeconds??0;
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
    var media  = Media.network(url);
    player.open(media);
    remote.setUrl(url);
  }

  @override
  void stop() {
    player.stop();
  }
}
