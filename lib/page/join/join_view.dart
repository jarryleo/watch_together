import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'join_logic.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({Key? key}) : super(key: key);

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final logic = Get.put(JoinLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Obx(() {
      return Center(
          child: logic.isLoading.value
              ? const CircularProgressIndicator()
              : buildInputWidget(context));
    }));
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
            Obx(() {
              return TextField(
                  controller: logic.roomIdController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: "请输入房间号",
                    errorText: logic.isError.value ? "请输入6位数的房间号" : null,
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  onSubmitted: (text) {
                    logic.joinRoom();
                  });
            }),
            MaterialButton(
                textColor: Colors.white,
                color: Colors.blue,
                child: const Text("加入"),
                onPressed: () {
                  logic.joinRoom();
                }),
          ],
        ),
      ),
    );
  }
}
