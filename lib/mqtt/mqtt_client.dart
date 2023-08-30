import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:watch_together/logger/log_utils.dart';

import 'mqtt_config.dart';
import 'mqtt_observer.dart';

class XMqttClient {
  static final XMqttClient _singleton = XMqttClient._internal();

  factory XMqttClient() {
    return _singleton;
  }

  XMqttClient._internal();

  MqttServerClient? _client;

  final List<XMqttObserver> _observers = [];

  void connect() async {
    //client
    MqttServerClient client = MqttServerClient.withPort(
        MqttConfig.host, MqttConfig.clientId, MqttConfig.port);
    _client = client;

    //config
    client.logging(on: false);
    client.secure = true;
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 60;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;

    //SSL
    var defaultContext = SecurityContext.defaultContext;
    defaultContext.setTrustedCertificates(MqttConfig.crtFile);
    client.securityContext = defaultContext;
    client.setProtocolV311();

    //callback
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    //connect
    try {
      //开始连接
      var mqttClientConnectionStatus =
          await client.connect(MqttConfig.username, MqttConfig.password);
      //检查连接结果
      if (MqttConnectionState.connected == mqttClientConnectionStatus?.state) {
        //连接成功
        //listener
        client.published?.listen(publishListen);
        client.updates?.listen(onDataArrived);
      } else {
        //链接失败
        QLog.e(
            'mqtt client connection failed - disconnecting, status is ${mqttClientConnectionStatus?.state}');
        client.disconnect();
      }
    } on Exception catch (e) {
      QLog.e('mqtt client exception - $e');
      client.disconnect();
    }
  }

  ///订阅mqtt主题
  void subscribe(String topic) {
    _client?.subscribe(topic, MqttQos.atLeastOnce);
  }

  void subscribeWithObserver(XMqttObserver observer) {
    _observers.add(observer);
    subscribe(observer.topic);
  }

  ///发送主题消息
  void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  ///发送回调监听
  void publishListen(MqttPublishMessage message) {
    final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
    QLog.d(
        'mqtt client publish listen: ${message.variableHeader?.topicName} - $payload');
  }

  ///接收回调监听
  void onDataArrived(List<MqttReceivedMessage<MqttMessage>> msgList) {
    for (var msg in msgList) {
      final String topic = msg.topic;
      final MqttMessage message = msg.payload;
      onMessageArriving(topic, message);
    }
  }

  ///接收消息监听
  void onMessageArriving(String topic, MqttMessage message) {
    final String msg = MqttPublishPayload.bytesToStringAsString(
        (message as MqttPublishMessage).payload.message);
    for (var observer in _observers) {
      if (topic == observer.topic) {
        observer.onMessage(topic, msg);
      }
    }
    QLog.d('mqtt client message arrived: $topic - $msg');
  }

  ///是否已连接
  bool isConnected() {
    return _client?.connectionStatus?.state == MqttConnectionState.connected;
  }

  void onConnected() {
    QLog.d('mqtt client Connected');
  }

  void onDisconnected() {
    QLog.d('mqtt client Disconnected');
  }

  void onSubscribed(String topic) {
    QLog.d('mqtt client Subscribed topic: $topic');
  }
}
