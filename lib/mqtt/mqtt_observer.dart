typedef OnMessage = void Function(String topic, String message);

class XMqttObserver {
  late String topic;
  late OnMessage onMessage;

  XMqttObserver(this.topic, this.onMessage);
}
