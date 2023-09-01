import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:watch_together/logger/log_utils.dart';
import 'package:watch_together/utils/client_id_util.dart';

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
  final List<OnConnected> _onConnectedListener = [];
  final List<OnDisconnected> _onDisconnectedListener = [];

  Future<bool> connect() async {
    //client
    MqttServerClient client = MqttServerClient.withPort(
        MqttConfig.host, ClientIdUtil.getClientId(), MqttConfig.port);
    _client = client;

    //config
    client.logging(on: false);
    client.secure = true;
    client.keepAlivePeriod = 60;
    client.connectTimeoutPeriod = 60;
    client.autoReconnect = true;
    //client.resubscribeOnAutoReconnect = true;

    //SSL
    var defaultContext = SecurityContext.defaultContext;
    defaultContext.setTrustedCertificates(MqttConfig.crtFile);
    client.securityContext = defaultContext;
    client.setProtocolV311();

    //callback
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    //connect
    try {
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
    _client?.disconnect();
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
    builder.addString(message);
    _client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  ///发送回调监听
  void _publishListen(MqttPublishMessage message) {
    final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);
    QLog.d(
        'mqtt client publish listen: ${message.variableHeader?.topicName} - $payload');
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
    QLog.d('mqtt client Disconnected');
  }

  void _onSubscribed(String topic) {
    QLog.d('mqtt client Subscribed topic: $topic');
  }
}
