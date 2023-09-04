import 'player_info.dart';

///房间信息管理
class RoomInfo {
  static final RoomInfo _singleton = RoomInfo._internal();

  factory RoomInfo() {
    return _singleton;
  }

  RoomInfo._internal();

  ///房间号 6位数字 字符串
  static String roomId = "";

  ///是否是房主
  static bool isOwner = false;

  ///房间播放状态
  static PlayerInfo playerInfo = PlayerInfo();

  ///重置房间信息
  static void reset() {
    roomId = "";
    isOwner = false;
    playerInfo = PlayerInfo();
  }
}
