import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 传递json对象实体
class PlayStateModel {
  //执行动作 [] 客户端发送专属信息 {} 服务端发送专属信息 ，其它为播放器通用信息
  // url,play,pause,seek, 播放器指令
  // [heartbeat 只有房主心跳同步播放状态,join 加入房间或者创建,sync 请求同步房主进度],
  // {idle 新房间,wait 等待房主开播}
  // exit 退出房间/解散房间
  String action = "join";
  String url = ""; //播放地址
  String roomId = ""; //房间id 6位int值
  bool isPlaying = false; // 是否正在播放
  bool isOwner = false; // 是否是房主
  int position = 0; //播放进度 单位 秒
  int timestamp = 0; //时间戳 单位 毫秒

  PlayStateModel(
      {this.action = "join",
      this.isPlaying = false,
      this.isOwner = false,
      this.position = 0,
      this.roomId = "",
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

  ///拷贝
  PlayStateModel copyWith({
    String? action,
    bool? isPlaying,
    bool? isOwner,
    int? position,
    String? roomId,
    int? timestamp,
    String? url,
  }) =>
      PlayStateModel(
        action: action ?? this.action,
        isPlaying: isPlaying ?? this.isPlaying,
        isOwner: isOwner ?? this.isOwner,
        position: position ?? this.position,
        roomId: roomId ?? this.roomId,
        timestamp: timestamp ?? this.timestamp,
        url: url ?? this.url,
      );
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
