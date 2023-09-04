// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:watch_together/dlna/dlna_flutter.dart';

void main() {
  test("localIp", () async {
    var activeIpList = List.empty(growable: true);
    var list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (var element in list) {
      for (var address in element.addresses) {
        activeIpList.add(address.address);
      }
    }
    print(activeIpList);
  });

  test("dlna test", () async {
    final searcher = Search();
    final m = await searcher.start();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      m.deviceList.forEach((key, value) async {
        print(key);
        if (value.info.friendlyName.contains('Wireless')) return;
        print(value.info.friendlyName);
        // final text = await value.position();
        // final r = await value.seekByCurrent(text, 10);
        // print(r);
      });
    });

    // close the server,the closed server can be start by call searcher.start()
    Timer(const Duration(seconds: 30), () {
      searcher.stop();
      print('server closed');
    });
  });

  test("dateFormat", () {
    var date = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
        .format(DateTime.now());
    print(date);
    var time = const Duration(seconds: 5000).toString();
    var t = time.split(".")[0];
    print(t);
  });

  test("http", () async {
    var host = InternetAddress.loopbackIPv4.host;
    var port = 8888;
    var url = "http://127.0.0.1:$port";
    var httpServer = await HttpServer.bind(host, port);
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      print("post");
      // HttpClient().post(url, port,"path");
      var client = HttpClient();
      var request = await client.get(url, port, "/path");
      request.write("hello");
      client.close();
    });
    await httpServer.forEach((request) {
      var path = request.uri.path;
      print(path);
    });
  });
}
