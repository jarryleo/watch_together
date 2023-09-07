import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/widget/widget_send_danmaku.dart';

import 'phone_video_logic.dart';

class PhoneVideoPage extends StatelessWidget {
  const PhoneVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    var logic = Get.put(PhoneVideoLogic());
    return WillPopScope(
      onWillPop: () {
        logic.exitRoom();
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            return Text(
                "房间号：${RoomInfo.roomId}(${logic.isRoomOwner.value ? "房主" : "观众"})");
          }),
        ),
        body: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16.0 / 9.0,
                  child: FijkView(
                    panelBuilder: fijkPanel2Builder(),
                    player: logic.player,
                    color: Colors.black,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: BarrageWall(
                    controller: logic.barrageWallController,
                    child: Container(),
                  ),
                )
              ],
            ),
            SendDanmakuInput(onSend: logic.sendDanmaku),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Text('''
1.由于各主流视频平台对于投屏协议的收紧，
 目前测试只有百度网盘手机app全屏播放时能投屏本app，
 开发者可以自行研究其他平台的投屏协议；
2.如果视频播放进度误差过大，请检查各方手机系统时间是否相差过大；
3.不支持本地视频投屏；
4.后续考虑支持填写视频播放地址；
                 '''),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => logic.sync(),
          child: const Icon(Icons.sync),
        ),
      ),
    );
  }
}
