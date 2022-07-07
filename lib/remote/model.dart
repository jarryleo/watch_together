import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 传递json对象实体
class PlayStateModel {
  String action = "url"; //执行动作 url,play,pause,seek,heartbeat
  String url = ""; //播放地址
  int position = 0; //播放进度 单位 秒
  int timestamp = 0; //时间戳 单位 毫秒

  Map toJson() {
    return {
      'action': action,
      'url': url,
      'position': position,
      'timestamp': timestamp
    };
  }
}

/// json 和对象互转工具类
class JsonParse {
  static String modelToJson(PlayStateModel model) {
    return jsonEncode(model);
  }

  static PlayStateModel? jsonToModel(String json) {
    try {
      return jsonDecode(json);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }
}
