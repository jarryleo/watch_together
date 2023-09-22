
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/page/main/main_logic.dart';
import 'package:watch_together/route/router_helper.dart';

mixin DlnaOnMainLogic on MainLogic {
  final DlnaServer dlnaServer = DlnaServer(name: RouterHelper.appName);

  @override
  void onRoomOwnerChanged(bool isRoomOwner) {
    super.onRoomOwnerChanged(isRoomOwner);
    if (isRoomOwner) {
      dlnaServer.start(this);
    } else {
      dlnaServer.stop();
    }
  }

  @override
  void exitRoom() {
    super.exitRoom();
    dlnaServer.stop();
  }
}