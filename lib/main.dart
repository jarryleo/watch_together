import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dlna/dlna_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dlna',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Dlna demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements DlnaAction {
  DlnaServer dlnaServer = DlnaServer();

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    dlnaServer.start(this);
    _controller = VideoPlayerController.network("")
      ..initialize().then((value) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    dlnaServer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller))
              : Container(
                  child: const Text("没有可播放的视频"),
                )),
    );
  }

  @override
  int getPosition() {
    return _controller.value.position.inSeconds;
  }

  @override
  int getDuration() {
    return _controller.value.duration.inSeconds;
  }

  @override
  int getVolume() {
    return _controller.value.volume.toInt();
  }
  @override
  void pause() {
    _controller.pause();
  }

  @override
  void play() {
    _controller.play();
  }

  @override
  void seek(int position) {
    _controller.seekTo(Duration(seconds: position));
  }

  @override
  void setUrl(String url) {
    _controller = VideoPlayerController.network(url)
      ..initialize().then((value) {
        setState(() {});
      });
  }

  @override
  void stop() {
    _controller.pause();
    _controller.seekTo(const Duration(seconds: 0));
  }

}
