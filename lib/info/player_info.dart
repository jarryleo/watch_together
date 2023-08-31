import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 传递json对象实体
class PlayerInfo {
  String url = ""; //播放地址
  bool isPlaying = false; // 是否正在播放
  int position = 0; //播放进度 单位 秒

  PlayerInfo({this.isPlaying = false, this.position = 0, this.url = ""});

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      url: json['url'],
      isPlaying: json['isPlaying'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isPlaying'] = isPlaying;
    data['position'] = position;
    data['url'] = url;
    return data;
  }

  String toJsonString() {
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
