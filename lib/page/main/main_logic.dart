import 'package:get/get.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';
import 'package:watch_together/page/main/main_service.dart';

class MainLogic extends GetxController implements PlayerAction {
  final DlnaServer dlnaServer = DlnaServer();
  final MainService mainService = Get.find<MainService>();
  
  @override
  void onInit() {
    super.onInit();
    mainService.setCallback(this);
    //房主才启动投屏功能 todo
    dlnaServer.start(this);
  }

  @override
  void dispose() {
    super.dispose();
    mainService.exit();
    dlnaServer.stop();
  }

  @override
  int getDuration() {
    // TODO: implement getDuration
    throw UnimplementedError();
  }

  @override
  int getPosition() {
    // TODO: implement getPosition
    throw UnimplementedError();
  }

  @override
  int getVolume() {
    // TODO: implement getVolume
    throw UnimplementedError();
  }

  @override
  void pause() {
    // TODO: implement pause
  }

  @override
  void play() {
    // TODO: implement play
  }

  @override
  void seek(int position) {
    // TODO: implement seek
  }

  @override
  void setUrl(String url) {
    // TODO: implement setUrl
  }

  @override
  void stop() {
    // TODO: implement stop
  }
}
