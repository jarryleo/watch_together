import 'package:fijkplayer/fijkplayer.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';

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
            AspectRatio(
              aspectRatio: 16.0 / 9.0,
              child: FijkView(
                panelBuilder: fijkPanel2Builder(),
                player: logic.player,
                color: Colors.black,
              ),
            )
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
