import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 传递json对象实体
class PlayStateModel {
  String action = "join"; //执行动作 url,play,pause,seek,heartbeat,join,sync,idle,wait
  String url = ""; //播放地址
  String roomId = "000000"; //房间id 6位int值
  bool isPlaying = false; // 是否正在播放
  bool isOwner = false; // 是否是房主
  int position = 0; //播放进度 单位 秒
  int timestamp = 0; //时间戳 单位 毫秒

  PlayStateModel({
    this.action = "join",
    this.isPlaying = false,
    this.isOwner = false,
    this.position = 0,
    this.roomId = "000000",
    this.timestamp = 0,
    this.url = ""});

  factory PlayStateModel.fromJson(Map<String, dynamic> json) {
    return PlayStateModel(
      action: json['action'],
      isPlaying: json['isPlaying'],
      isOwner: json['isOwner'],
      position: json['position'],
      roomId: json['roomId'],
      timestamp: json['timestamp'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['action'] = action;
    data['isPlaying'] = isPlaying;
    data['isOwner'] = isOwner;
    data['position'] = position;
    data['roomId'] = roomId;
    data['timestamp'] = timestamp;
    data['url'] = url;
    return data;
  }
}

/// json 和对象互转工具类
class JsonParse {
  static String modelToJson(PlayStateModel model) {
    return jsonEncode(model);
  }

  static PlayStateModel jsonToModel(String json) {
    try {
      return PlayStateModel.fromJson(jsonDecode(json));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return PlayStateModel();
    }
  }
}
