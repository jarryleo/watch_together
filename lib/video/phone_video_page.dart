import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../dlna/dlna_flutter.dart';

class PhoneVideoPage extends StatefulWidget {
  const PhoneVideoPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<PhoneVideoPage> createState() => _PhoneVideoPageState();
}

class _PhoneVideoPageState extends State<PhoneVideoPage> implements DlnaAction {
  DlnaServer dlnaServer = DlnaServer();

  FijkPlayer player = FijkPlayer();

  @override
  void initState() {
    super.initState();
    dlnaServer.start(this);
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    dlnaServer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16.0 / 9.0,
              child: FijkView(
                player: player,
                color: Colors.black,
              ),
            )
          ],
        ));
  }

  @override
  int getPosition() {
    return player.currentPos.inSeconds;
  }

  @override
  int getDuration() {
    return player.value.duration.inSeconds;
  }

  @override
  int getVolume() {
    return 0;
  }

  @override
  void pause() {
    if (player.isPlayable()) {
      player.pause();
    }
  }

  @override
  void play() {
    player.start();
  }

  @override
  void seek(int position) {
    player.seekTo(position * 1000);
  }

  @override
  void setUrl(String url) {
    player.setDataSource(url, autoPlay: true);
  }

  @override
  void stop() {
    player.stop();
    player.reset();
  }
}
