import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../includes.dart';

typedef UrlCallBack = void Function(String value);

class InputVideoUrlDialog extends StatelessWidget {
  InputVideoUrlDialog({super.key, required this.onInputUrlCallback});

  final UrlCallBack onInputUrlCallback;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            controller: _controller,
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
                  onInputUrlCallback(_controller.text);
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
