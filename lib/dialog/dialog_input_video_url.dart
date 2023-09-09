import 'dart:io';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:watch_together/page/video/desktop/desktop_video_logic.dart';
import 'package:watch_together/page/video/phone/phone_video_logic.dart';

import '../includes.dart';

class InputVideoUrlDialog extends StatelessWidget {
  const InputVideoUrlDialog({super.key});

  @override
  Widget build(BuildContext context) {
    var logic = (Platform.isAndroid || Platform.isIOS)
        ? Get.find<PhoneVideoLogic>()
        : Get.find<DesktopVideoLogic>();
    return Container(
      width: 320,
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            '请输入视频地址',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: logic.urlController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '请输入视频地址',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  SmartDialog.dismiss();
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  logic.inputUrl();
                  SmartDialog.dismiss();
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
