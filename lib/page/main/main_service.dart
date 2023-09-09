import 'dart:async';

import 'package:async/async.dart';
import 'package:get/get.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/info/player_info.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/mqtt/mqtt_client.dart';
import 'package:watch_together/mqtt/mqtt_observer.dart';
import 'package:watch_together/mqtt/mqtt_topic.dart';

class MainService extends GetxService {
  final XMqttClient mqttClient = XMqttClient();
  final StreamController<bool> _roomOwnerController =
      StreamController<bool>.broadcast();
  final StreamController<String> _danmakuStreamController =
      StreamController<String>.broadcast();
  PlayerAction? _callback;
  bool _roomHasOwner = false;
  CancelableOperation? _cancelableOperation;

  //延迟时间，发起同步请求，到获取结果的延迟，用于计算播放进度
  int _delayTime = 0;

  //发起同步的时间
  int _syncTime = 0;

  Future<MainService> init() async {
    mqttClient.addOnConnectedListener(_onConnected);
    mqttClient.addOnDisconnectedListener(_onDisconnected);
    return this;
  }

  ///连接服务器成功
  void _onConnected() {
    //先以游客身份入房，如果5s没有收到房主的同步信息，自动成为房主
    _beGuest();
    _subscribe(ActionTopic.danmaku); //订阅弹幕消息
    _syncTime = DateTime.now().millisecondsSinceEpoch;
    _pushAction(ActionTopic.join);
    //检查房间是否有房主
    _checkRoomOwner();
  }

  ///服务器离线
  void _onDisconnected() {
    _beGuest();
  }

  ///订阅action topic
  void _subscribe(ActionTopic topic) {
    if (mqttClient.isConnected()) {
      mqttClient.subscribeWithObserver(XMqttObserver(
          topic.getTopicWithRoomId(RoomInfo.roomId), _onMsgArrived));
    }
  }

  ///取消订阅action topic
  void _unsubscribe(ActionTopic topic) {
    if (mqttClient.isConnected()) {
      mqttClient.unsubscribe(topic.getTopicWithRoomId(RoomInfo.roomId));
    }
  }

  ///解析action topic
  void _parseAction(String topic, String message) {
    var action = ActionTopic.getActionTopic(topic);
    switch (action) {
      case ActionTopic.join:
        //是房主，接收到他人入房信息，同步播放信息
        if (RoomInfo.isOwner) {
          _pushAction(ActionTopic.state,
              message: RoomInfo.playerInfo.toJsonString());
        }
        break;
      case ActionTopic.play:
        int position = int.tryParse(message) ?? 0;
        _callback?.play();
        _seek(position);
        break;
      case ActionTopic.pause:
        int position = int.tryParse(message) ?? 0;
        _callback?.pause();
        _seek(position);
        break;
      case ActionTopic.seek:
        int position = int.tryParse(message) ?? 0;
        _seek(position);
        break;
      case ActionTopic.sync:
        //是房主，接收到他人请求同步信息，同步播放信息
        if (RoomInfo.isOwner) {
          _pushAction(ActionTopic.state,
              message: RoomInfo.playerInfo.toJsonString());
        }
        break;
      case ActionTopic.state:
        //计算延迟
        _delayTime = DateTime.now().millisecondsSinceEpoch - _syncTime;
        //收到房主同步信息，表示房间有房主
        _roomHasOwner = true;
        //接收到房主的播放信息，同步本地播放器
        var playerInfo = PlayerInfo.fromJsonString(message);
        //如果url不一样，说明房主切换了视频，需要重新设置url
        if (playerInfo.url != RoomInfo.playerInfo.url) {
          _callback?.setUrl(playerInfo.url);
        }
        if (playerInfo.url.isEmpty) {
          _callback?.stop();
          return;
        }
        //同步进度
        int position = playerInfo.position + _delayTime ~/ 1000;
        _callback?.seek(position);
        //播放暂停同步
        if (playerInfo.isPlaying) {
          _callback?.play();
        } else {
          _callback?.pause();
        }
        playerInfo.position = position;
        RoomInfo.playerInfo = playerInfo;
        break;
      case ActionTopic.danmaku:
        //收到弹幕消息
        _danmakuStreamController.sink.add(message);
        break;
      default:
        break;
    }
  }

  ///sync remote seek
  void _seek(int position) {
    var fixPosition = position + _delayTime ~/ 1000;
    RoomInfo.playerInfo.position = fixPosition;
    _callback?.seek(fixPosition);
  }

  ///发送action topic
  void _pushAction(ActionTopic topic, {String message = '0'}) {
    if (!mqttClient.isConnected()) return;
    var data = message;
    if (message.isEmpty) {
      data = '0';
    }
    mqttClient.publish(topic.getTopicWithRoomId(RoomInfo.roomId), data);
  }

  void _onMsgArrived(String topic, String message) {
    QLog.d('mqtt client message arrived: $topic - $message');
    _parseAction(topic, message);
  }

  void setPlayerInfoCallback(PlayerAction? callback) {
    _callback = callback;
  }

  Stream<bool> getRoomOwnerStream() {
    return _roomOwnerController.stream;
  }

  Stream<String> getDanmakuStream() {
    return _danmakuStreamController.stream;
  }

  ///加入房间
  Future<bool> join(String roomId) async {
    QLog.d("join room");
    RoomInfo.roomId = roomId;
    return mqttClient.connect();
  }

  ///退出房间
  void exit() {
    _cancelableOperation?.cancel();
    _cancelableOperation = null;
    _callback = null;
    mqttClient.disconnect();
    RoomInfo.reset();
    QLog.d("exit room");
  }

  ///请求房主同步播放信息，5秒没收到回复则自动成为房主
  void sync() {
    if (RoomInfo.isOwner) return;
    _syncTime = DateTime.now().millisecondsSinceEpoch;
    _pushAction(ActionTopic.sync);
    _checkRoomOwner();
  }

  void play() {
    if (!RoomInfo.isOwner) return;
    _pushAction(ActionTopic.play,
        message: RoomInfo.playerInfo.position.toString());
  }

  void pause() {
    if (!RoomInfo.isOwner) return;
    _pushAction(ActionTopic.pause,
        message: RoomInfo.playerInfo.position.toString());
  }

  void seek(int position) {
    if (!RoomInfo.isOwner) return;
    _pushAction(ActionTopic.seek, message: position.toString());
  }

  void setUrl(String url) {
    if (!RoomInfo.isOwner) return;
    _pushAction(ActionTopic.state, message: RoomInfo.playerInfo.toJsonString());
  }

  void _checkRoomOwner() {
    _roomHasOwner = false;
    //倒计时5秒
    var future = Future.delayed(const Duration(seconds: 5), () {
      if (_callback == null) return;
      if (!_roomHasOwner) {
        //空房间，自动成为房主
        _beOwner();
        _pushAction(ActionTopic.state,
            message: RoomInfo.playerInfo.toJsonString());
      }
    });
    _cancelableOperation = CancelableOperation.fromFuture(future, onCancel: () {
      QLog.d("cancel check room owner");
    });
  }

  ///成为房主,需监听加入房间信息，和请求同步播放进度信息，其它信息忽略
  void _beOwner() {
    RoomInfo.isOwner = true;
    _subscribe(ActionTopic.join);
    _subscribe(ActionTopic.sync);
    _unsubscribe(ActionTopic.play);
    _unsubscribe(ActionTopic.pause);
    _unsubscribe(ActionTopic.seek);
    _unsubscribe(ActionTopic.state);
    _roomOwnerController.sink.add(RoomInfo.isOwner);
  }

  ///成为客户端，需监听播放，暂停，跳转，同步播放进度信息，其它信息忽略
  void _beGuest() {
    RoomInfo.isOwner = false;
    _subscribe(ActionTopic.play);
    _subscribe(ActionTopic.pause);
    _subscribe(ActionTopic.seek);
    _subscribe(ActionTopic.state);
    _unsubscribe(ActionTopic.join);
    _unsubscribe(ActionTopic.sync);
    _roomOwnerController.sink.add(RoomInfo.isOwner);
  }

  ///发送弹幕消息
  void sendDanmaku(String message) {
    _pushAction(ActionTopic.danmaku, message: message);
  }
}
