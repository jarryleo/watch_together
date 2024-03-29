import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/widget/widget_send_danmaku.dart';

import '../../../includes.dart';
import 'web_logic.dart';

class WebPage extends StatelessWidget {
  const WebPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(WebLogic());
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
            Obx(() {
              return Visibility(
                visible: logic.isRoomOwner.value,
                child: IconButton(
                  icon: const Icon(Icons.input),
                  tooltip: '输入视频地址',
                  onPressed: () => logic.showInputUrlDialog(),
                ),
              );
            }),
            Obx(() {
              return Visibility(
                visible: !logic.isRoomOwner.value,
                child: IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: '同步进度',
                  onPressed: () => logic.sync(),
                ),
              );
            }),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SafeArea(
                    child: GetBuilder<WebLogic>(builder: (logic) {
                      return CustomVideoPlayer(
                          customVideoPlayerController:
                              logic.customVideoPlayerController!);
                    }),
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
              return Visibility(
                visible: logic.isDanmakuInputShow.value,
                child: SendDanmakuInput(
                  onSend: (text) => logic.sendDanmaku(text),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
