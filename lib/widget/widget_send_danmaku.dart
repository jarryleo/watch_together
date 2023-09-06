import '../includes.dart';

typedef ValueCallBack = void Function(String value);

class SendDanmakuInput extends StatelessWidget {
  SendDanmakuInput({super.key, this.onSend});

  final ValueCallBack? onSend;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '发送弹幕',
              ),
              onSubmitted: (value) {
                onSend?.call(value);
                _controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              onSend?.call(_controller.text);
              _controller.clear();
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Icon(
              Icons.send,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
