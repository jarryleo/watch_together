import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 传递json对象实体
class PlayerInfo {
  String url = ""; //播放地址
  bool isPlaying = false; // 是否正在播放
  int position = 0; //播放进度 单位 秒
  int timeStamp = 0; //时间戳

  PlayerInfo(
      {this.url = "",
      this.isPlaying = false,
      this.position = 0,
      this.timeStamp = 0});

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      url: json['url'],
      isPlaying: json['isPlaying'],
      position: json['position'],
      timeStamp: json['timeStamp'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['isPlaying'] = isPlaying;
    data['position'] = position;
    data['timeStamp'] = timeStamp;
    return data;
  }

  int getFixPosition() {
    if (timeStamp == 0) {
      return position;
    }
    var nowTimeStamp = DateTime.now().millisecondsSinceEpoch;
    //如果本地时间比房主时间慢，则无法修正
    if (nowTimeStamp < timeStamp) {
      return position;
    }
    //修正播放进度时间差（前提时用户系统时间一致）
    var diffSec = (nowTimeStamp - timeStamp + 900) ~/ 1000;
    return position + diffSec;
  }

  String toJsonString() {
    timeStamp = DateTime.now().millisecondsSinceEpoch;
    return jsonEncode(toJson());
  }

  static PlayerInfo fromJsonString(String json) {
    try {
      return PlayerInfo.fromJson(jsonDecode(json));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return PlayerInfo();
    }
  }

  ///拷贝
  PlayerInfo copyWith({
    String? url,
    bool? isPlaying,
    int? position,
  }) =>
      PlayerInfo(
        url: url ?? this.url,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
      );
}
