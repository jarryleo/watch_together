import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:watch_together/logger/log_utils.dart';

import 'mqtt_config.dart';
import 'mqtt_observer.dart';

abstract class XMqttClient {
  MqttClient? _client;

  final List<XMqttObserver> _observers = [];
  final List<OnConnected> _onConnectedListener = [];
  final List<OnDisconnected> _onDisconnectedListener = [];

  Future<MqttClient> buildClient();

  Future<bool> connect() async {
    MqttClient client = await buildClient();
    _client = client;
    //config
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 60;
    client.autoReconnect = false;
    client.resubscribeOnAutoReconnect = false;

    //callback
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    //connect
    try {
      client.setProtocolV311();
      //开始连接
      var mqttClientConnectionStatus =
          await client.connect(MqttConfig.username, MqttConfig.password);
      //检查连接结果
      if (MqttConnectionState.connected == mqttClientConnectionStatus?.state) {
        //连接成功
        //listener
        client.published?.listen(_publishListen);
        client.updates?.listen(_onDataArrived);
        return true;
      } else {
        //连接失败
        QLog.e(
            'mqtt client connection failed - disconnecting, status is ${mqttClientConnectionStatus?.state}');
        client.disconnect();
        return false;
      }
    } on Exception catch (e) {
      QLog.e('mqtt client exception - $e');
      client.disconnect();
      return false;
    }
  }

  ///断开连接
  void disconnect() {
    if (isConnected()) {
      _client?.disconnect();
    } else {
      QLog.d('mqtt client already disconnected');
    }
  }

  ///订阅mqtt主题
  void _subscribe(String topic) {
    _client?.subscribe(topic, MqttQos.atLeastOnce);
  }

  ///取消主题订阅
  void unsubscribe(String topic) {
    _client?.unsubscribe(topic);
    _observers.removeWhere((element) => element.topic == topic);
  }

  ///订阅mqtt主题回调
  void subscribeWithObserver(XMqttObserver observer) {
    _observers.add(observer);
    _subscribe(observer.topic);
  }

  ///发送主题消息
  void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addUTF8String(message);
    _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    QLog.d('mqtt client publish: $topic - $message');
  }

  ///发送回调监听
  void _publishListen(MqttPublishMessage message) {
    /*final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
    QLog.d(
        'mqtt client publish listen: ${message.variableHeader?.topicName} - $payload');*/
  }

  ///接收回调监听
  void _onDataArrived(List<MqttReceivedMessage<MqttMessage>> msgList) {
    for (var msg in msgList) {
      final String topic = msg.topic;
      final MqttMessage message = msg.payload;
      _onMessageArriving(topic, message);
    }
  }

  ///接收消息监听
  void _onMessageArriving(String topic, MqttMessage message) {
    var buffer = (message as MqttPublishMessage).payload.message;
    //UTF-8 解码
    const decoder = Utf8Decoder();
    final String msg = decoder.convert(buffer);
    //final String msg = MqttPublishPayload.bytesToStringAsString(buffer);
    for (var observer in _observers) {
      if (topic == observer.topic) {
        observer.onMessage(topic, msg);
      }
    }
  }

  ///是否已连接
  bool isConnected() {
    return _client?.connectionStatus?.state == MqttConnectionState.connected;
  }

  ///添加连接监听
  void addOnConnectedListener(OnConnected listener) {
    _onConnectedListener.add(listener);
  }

  ///添加断开连接监听
  void addOnDisconnectedListener(OnDisconnected listener) {
    _onDisconnectedListener.add(listener);
  }

  void _onConnected() {
    for (var element in _onConnectedListener) {
      element();
    }
    QLog.d('mqtt client Connected');
  }

  void _onDisconnected() {
    for (var element in _onDisconnectedListener) {
      element();
    }
    _observers.clear();
    QLog.d('mqtt client Disconnected');
  }

  void _onSubscribed(String topic) {
    QLog.d('mqtt client Subscribed topic: $topic');
  }
}
