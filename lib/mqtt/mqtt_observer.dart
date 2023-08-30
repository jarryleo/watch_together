typedef OnMessage = void Function(String topic, String message);
typedef OnConnected = void Function();
typedef OnDisconnected = void Function();

class XMqttObserver {
  late String topic;
  late OnMessage onMessage;

  XMqttObserver(this.topic, this.onMessage);
}
