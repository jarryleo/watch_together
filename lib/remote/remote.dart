
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/remote/model.dart';

/// 同步服务端地址
const host = "bigplans.work";
const int remotePort = 51127; //服务器端口

///跟服务端交互，获取 播放状态
class Remote {

  PlayerAction? _callback;

  ///远程状态
  final PlayStateModel _remoteState =  PlayStateModel();

  RawDatagramSocket? _socket;
  ///远端地址
  InternetAddress? remoteAddress;

  Remote(){
    Future.microtask((){
      _start();
    });
  }

  void _start() async {
    InternetAddress.lookup(host).then((list){
      if (kDebugMode) {
        print(list);
      }
      remoteAddress = list.first;
      if(remoteAddress == null) return;
      RawDatagramSocket.bind(InternetAddress.anyIPv4, remotePort).then((socket){
        _socket = socket;
        _listen();
        Timer.periodic(const Duration(seconds: 5), (timer) {
          _heartbeat();
        });
      });
    });
  }

  ///设置播放回调
  void setCallback(PlayerAction callback){
    _callback = _callback;
  }

  /// 接收对面数据
  void _listen() {
    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        var dg = _socket?.receive();
        if (dg != null) {
          var text = String.fromCharCodes(dg.data);
          _parse(text);
        }
      }
    });
  }

  ///发送当前状态
  void _send(PlayStateModel model){
    var json = JsonParse.modelToJson(model);
    if (kDebugMode) {
      print(json);
    }
    var address = remoteAddress;
    if (address == null) return;
    _socket?.send(utf8.encode(json), address, remotePort);
  }

  /// json 转对象
  void _parse(String text){
    PlayStateModel? model = JsonParse.jsonToModel(text);
    if (model != null){
      _doAction(model);
    }
  }
  ///执行对方的动作
  void _doAction(PlayStateModel model){
    var action = model.action;

    switch (action){
      case 'url':
        // 设置播放地址
        _callback?.setUrl(model.url);
        break;
      case 'play':
        // 播放视频
        _callback?.play();
        break;
      case 'pause':
        // 暂停视频
        _callback?.pause();
        break;
      case 'seek':
        // 进度跳转
        _callback?.seek(model.position);
        break;
    }
  }

  /// 加入房间或者创建房间
  void join(String roomId) {
    if (roomId.isEmpty) return;
    var model = _remoteState;
    model.action = "join";
    model.roomId = roomId;
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  /// 接收到投屏的视频地址，发送给远端
  void setUrl(String url){
    if(_remoteState.url == url) return;
    var model = _remoteState;
    model.action = "url";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _remoteState.url = url;
    _send(model);
  }
  ///播放视频
  void play(){
    var model = _remoteState;
    model.action = "play";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///暂停视频
  void pause(){
    var model = _remoteState;
    model.action = "pause";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///同步进度
  void seek(int position){
    var model = _remoteState;
    model.action = "seek";
    model.position = position;
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///和远程同步进度
  void syncRemote(){
    var model = _remoteState;
    model.action = "sync";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///心跳
  void _heartbeat(){
    var model = _remoteState;
    model.action = "heartbeat";
    model.position = _callback?.getPosition() ?? 0;
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  void dispose(){
    _socket?.close();
  }
}
