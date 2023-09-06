import 'package:dart_vlc/dart_vlc.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/video/desktop/desktop_video_logic.dart';

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
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'sync',
              onPressed: () => logic.sync(),
            ),
          ],
        ),
        body: Video(
          player: logic.player,
          volumeThumbColor: Colors.blue,
          volumeActiveColor: Colors.blue,
        ),
      ),
    );
  }
}
