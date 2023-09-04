import 'package:dart_vlc/dart_vlc.dart';
import 'package:watch_together/includes.dart';
import 'package:watch_together/info/room_info.dart';
import 'package:watch_together/page/video/desktop/desktop_video_logic.dart';

class DesktopVideoPage extends StatefulWidget {
  const DesktopVideoPage({super.key});

  @override
  State<DesktopVideoPage> createState() => _DesktopVideoPageState();
}

class _DesktopVideoPageState extends State<DesktopVideoPage> {
  @override
  Widget build(BuildContext context) {
    var logic = Get.put(DesktopVideoLogic());
    return Scaffold(
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
    );
  }
}
