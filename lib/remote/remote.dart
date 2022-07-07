
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:watch_together/remote/model.dart';

/// 同步服务端地址
final InternetAddress remote_address = InternetAddress("jarryleo.vip.cc");
const int remote_port = 51127; //服务器端口

///跟服务端交互，获取另一个播放器的 播放状态
class Remote {

  RemoteCallback callback;

  ///远程状态
  PlayStateModel? remoteState;

  late RawDatagramSocket _socket;

  /// 是否是服务端，服务端接收客户端投屏
  bool _isServer = false;
  ///客户端地址
  InternetAddress? clientAddress;

  Remote(this.callback,{isServer = false}){
    _isServer = isServer;
    RawDatagramSocket.bind(remote_address, remote_port).then((socket){
      _socket = socket;
      _listen();
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _heartbeat();
    });
  }

  /// 接收对面数据
  void _listen() {
    _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        var dg = _socket.receive();
        if (dg != null) {
          if(_isServer){
            clientAddress = dg.address;
          }
          var text = String.fromCharCodes(dg.data);
          _parse(text);
        }
      }
    });
  }

  ///发送当前状态
  void _send(PlayStateModel model){
    var json = JsonParse.modelToJson(model);
    var address = remote_address;
    if(_isServer && clientAddress != null){
      address = clientAddress!;
    }
    _socket.send(utf8.encode(json), address, remote_port);
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
        callback.setUrl(model.url);
        break;
      case 'play':
        // 播放视频
        callback.play();
        break;
      case 'pause':
        // 暂停视频
        callback.pause();
        break;
      case 'seek':
        // 进度跳转
        callback.seek(model.position);
        break;
      case 'heartbeat':
        // 进度跳转
        remoteState = model;
        break;
    }
  }

  /// 接收到投屏的视频地址，发送给远端
  void setUrl(String url){
    var model = PlayStateModel();
    model.action = "url";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }
  ///播放视频
  void play(){
    var model = PlayStateModel();
    model.action = "play";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///暂停视频
  void pause(){
    var model = PlayStateModel();
    model.action = "pause";
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///同步进度
  void seek(int position){
    var model = PlayStateModel();
    model.action = "seek";
    model.position = position;
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

  ///和远程同步进度
  void syncRemote(){
    if(remoteState == null) return;
    var position = remoteState!.position + 1;
    callback.seek(position);
  }

  ///心跳
  void _heartbeat(){
    var model = PlayStateModel();
    model.action = "heartbeat";
    model.position = callback.getPosition();
    model.timestamp = DateTime.now().millisecondsSinceEpoch;
    _send(model);
  }

}
///远程同步回调
abstract class RemoteCallback {
  int getPosition();
  void setUrl(String url);
  void play();
  void pause();
  void seek(int position);
}