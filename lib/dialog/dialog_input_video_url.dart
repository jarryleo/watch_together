import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:watch_together/page/video/desktop/desktop_video_logic.dart';

import '../includes.dart';

class InputVideoUrlDialog extends StatelessWidget {
  const InputVideoUrlDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 200,
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
            controller: Get.find<DesktopVideoLogic>().urlController,
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
                  Get.find<DesktopVideoLogic>().inputUrl();
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
