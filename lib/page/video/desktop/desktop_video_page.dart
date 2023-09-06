import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/video/desktop/desktop_video_logic.dart';
import 'package:watch_together/widget/widget_send_danmaku.dart';

class DesktopVideoPage extends StatelessWidget {
  const DesktopVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    var logic = Get.put(DesktopVideoLogic());
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
          actions: [
            Obx(() {
              return IconButton(
                icon: Icon(
                  Icons.send,
                  color: logic.isDanmakuInputShow.value
                      ? Colors.yellowAccent
                      : Colors.white,
                ),
                tooltip: '发送弹幕',
                onPressed: () {
                  logic.isDanmakuInputShow.value =
                      !logic.isDanmakuInputShow.value;
                },
              );
            }),
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'sync',
              onPressed: () => logic.sync(),
            ),
          ],
        ),
        body: Column(
          children: [
            Flexible(
              child: Stack(
                children: [
                  Video(
                    player: logic.player,
                    volumeThumbColor: Colors.blue,
                    volumeActiveColor: Colors.blue,
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
            ),
            Obx(() {
              return Column(
                children: [
                  if (logic.isDanmakuInputShow.value)
                    SendDanmakuInput(
                      onSend: (text) => logic.sendDanmaku(text),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
