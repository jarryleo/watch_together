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
            SendDanmakuInput(onSend: logic.sendDanmaku)
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
