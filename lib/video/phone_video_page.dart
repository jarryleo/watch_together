import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:watch_together/remote/remote.dart';

import '../dlna/dlna_flutter.dart';

class PhoneVideoPage extends StatefulWidget {
  final Remote remote;

  const PhoneVideoPage(this.remote, {Key? key}) : super(key: key);

  @override
  State<PhoneVideoPage> createState() => _PhoneVideoPageState();
}

class _PhoneVideoPageState extends State<PhoneVideoPage>
    implements PlayerAction {
  DlnaServer dlnaServer = DlnaServer();
  late Remote remote;
  FijkPlayer player = FijkPlayer();

  //当前播放的url
  var currentUrl = "";

  //播放状态
  bool _playing = false;
  Duration _currentPos = const Duration();

  @override
  void initState() {
    super.initState();
    remote = widget.remote;
    remote.setActionCallback(this);
    if(remote.isRoomOwner) {
      //房主才能开启投屏
      dlnaServer.start(this);
    }else{
      //观众同步房主信息
      remote.syncRemote();
    }
    player.addListener(_playerValueChanged);
    player.onCurrentPosUpdate.listen((pos) {
      //如果本地进度和播放器进度误差超过5s，则同步进度
      if((pos.inSeconds - _currentPos.inSeconds).abs() >=5){
        remote.seek(pos.inSeconds);
      }
      _currentPos = pos;
    });
  }

  //播放器状态监听(同步房间其他人)
  void _playerValueChanged() {
    FijkValue value = player.value;
    bool playing = (value.state == FijkState.started);
    if (playing != _playing) {
      //播放暂停控制
      if (playing) {
        remote.play();
      } else {
        remote.pause();
      }
      _playing = playing;
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
        title: Text("房间号：${remote.roomId}"),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: FijkView(
              panelBuilder: fijkPanel2Builder(),
              player: player,
              color: Colors.black,
            ),
          )
        ],
      ),
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
    if (url == currentUrl) return;
    player.setDataSource(url, autoPlay: true);
    remote.setUrl(url);
  }

  @override
  void stop() {
    currentUrl = "";
    player.stop();
    player.reset();
    remote.dispose();
  }
}
