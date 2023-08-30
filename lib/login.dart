import 'dart:io';

import 'package:flutter/material.dart';
import 'package:watch_together/page/video/desktop_video_page.dart';
import 'package:watch_together/page/video/phone_video_page.dart';
import 'package:watch_together/remote/remote.dart';

class JoinPage extends StatefulWidget {
  const JoinPage(this.remote, {Key? key}) : super(key: key);

  final Remote remote;

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  bool _isLoading = false;
  String? errText;
  String roomId = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : buildInputWidget(context)));
  }

  Widget buildInputWidget(BuildContext context) {
    return Card(
      child: Container(
          padding: const EdgeInsets.all(16),
          width: 300,
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: "请输入房间号",
                    errorText: errText,
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  onChanged: (text) {
                    roomId = text;
                    setState(() {
                      errText = null;
                    });
                  },
                  onSubmitted: (text) {
                    _join(text);
                  }),
              MaterialButton(
                  textColor: Colors.white,
                  color: Colors.blue,
                  child: const Text("加入"),
                  onPressed: () {
                    _join(roomId);
                  }),
            ],
          )),
    );
  }

  void _join(String roomId) {
    var tips = "请输入6位数字的房间号";
    if (roomId.length != 6) {
      //showToast(tips);
      setState(() {
        errText = tips;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    widget.remote.setRemoteCallback((result) {
      if (result) {
        _jump();
      }
      setState(() {
        _isLoading = false;
      });
    });
    widget.remote.join(roomId);
  }

  void _jump() {
    if(Platform.isWindows){
      Navigator.pop(context);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Platform.isAndroid || Platform.isIOS
          ? PhoneVideoPage(widget.remote)
          : Platform.isWindows || Platform.isLinux
              ? DesktopVideoPage(widget.remote)
              : const Center(child: Text("该设备不支持！"));
    }));
  }

  @override
  void dispose() {
    super.dispose();
    if(!Platform.isWindows) {
      widget.remote.dispose();
    }
  }
}
