import 'package:watch_together/info/room_info.dart';

///订阅主题
enum ActionTopic {
  join('join'),

  ///加入,加入后5秒没有收到房主同步信息，则自动创建房间
  play('play'),

  ///播放
  pause('pause'),

  ///暂停
  seek('seek'),

  ///跳转 参数为进度条时间，单位秒
  sync('sync'),

  ///弹幕消息
  danmaku('danmaku'),

  ///申请同步, 5s 没有收到state信息则表示房主离线，自动接替房主；
  state('state');

  ///同步状态，参数 url,isPlaying,position
  final String topic;

  const ActionTopic(this.topic);

  String getTopicWithRoomId(String roomId) {
    return '$roomId/$topic';
  }

  ///解析包含roomId的topic对应的action
  static ActionTopic getActionTopic(String topic) {
    for (var value in ActionTopic.values) {
      if (value.getTopicWithRoomId(RoomInfo.roomId) == topic) {
        return value;
      }
    }
    return ActionTopic.join;
  }
}
