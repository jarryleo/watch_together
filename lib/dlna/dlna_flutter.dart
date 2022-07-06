import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// dlna 常用组播地址和端口
const String _UPNP_IP_V4 = '239.255.255.250';
const int _UPNP_PORT = 1900;
final InternetAddress _UPNP_AddressIPv4 = InternetAddress(_UPNP_IP_V4);

/// 服务器常用xml
_XmlReplay? _xmlReplay;

/// 获取 随机 uuid
var _uuid = "27d6877e-${Random().nextInt(8999) + 1000}-ea12-abdf-cf8d50e36d54";

/// 删除字符串[from]尾部所有指定字符[pattern]
String _removeTrailing(String pattern, String from) {
  int i = from.length;
  while (from.startsWith(pattern, i - pattern.length)) {
    i -= pattern.length;
  }
  return from.substring(0, i);
}

/// 删除字符串[from]头部所有指定字符[pattern]
String _trimLeading(String pattern, String from) {
  int i = 0;
  while (from.startsWith(pattern, i)) {
    i += pattern.length;
  }
  return from.substring(i);
}

/// 秒数转成时分秒
String _secondToTime(int second) {
  var time = const Duration(seconds: 5000).toString();
  return time.split(".")[0];
}

/// html 编码
String _htmlEncode(String text) {
  Map<String, String> mapping = Map.from(
      {"&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': '&quot;'});
  mapping.forEach((key, value) {
    text = text.replaceAll(key, value);
  });
  return text;
}

/// 异步获取本机活动的ip地址
Future<List<String>> _getActiveLocalIpList() async {
  List<String> activeIpList = List.empty(growable: true);
  var list = await NetworkInterface.list(type: InternetAddressType.IPv4);
  for (var element in list) {
    for (var address in element.addresses) {
      activeIpList.add(address.address);
    }
  }
  return activeIpList;
}

/// 网络请求
class _Http {
  static final client = HttpClient();

  static Future<String> get(Uri uri) async {
    const timeout = Duration(seconds: 5);
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(timeout);
    if (res.statusCode != HttpStatus.ok) {
      throw Exception("request $uri error , status ${res.statusCode}");
    }
    final body = await res.transform(utf8.decoder).join().timeout(timeout);
    return body;
  }

  static Future<String> post(
      Uri uri, Map<String, Object> headers, List<int> data) async {
    const timeout = Duration(seconds: 5);
    final req = await client.postUrl(uri);
    headers.forEach((name, values) {
      req.headers.set(name, values);
    });
    req.contentLength = data.length;
    req.add(data);
    final res = await req.close().timeout(timeout);
    if (res.statusCode != HttpStatus.ok) {
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      throw Exception("request $uri error , status ${res.statusCode} $body");
    }
    final body = await res.transform(utf8.decoder).join().timeout(timeout);
    return body;
  }
}

/// xml 文本类
class _XmlText {
  static String setPlayURLXml(String url) {
    var title = url;
    final douyu = RegExp(r'^https?://(\d+)\?douyu$');
    final isDouyu = douyu.firstMatch(url);
    if (isDouyu != null) {
      final roomId = isDouyu.group(1);
      // 斗鱼tv的dlna server,只能指定直播间ID,不接受url资源,必须是如下格式
      title = "roomId = $roomId, line = 0";
    }
    var meta =
        '''<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/"><item id="false" parentID="1" restricted="0"><dc:title>$title</dc:title><dc:creator>unkown</dc:creator><upnp:class>object.item.videoItem</upnp:class><res resolution="4"></res></item></DIDL-Lite>''';
    meta = _htmlEncode(meta);
    url = _htmlEncode(url);
    return '''<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <CurrentURI>$url</CurrentURI>
            <CurrentURIMetaData>$meta</CurrentURIMetaData>
        </u:SetAVTransportURI>
    </s:Body>
</s:Envelope>
        ''';
  }

  static String playActionXml() {
    return '''<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Speed>1</Speed>
        </u:Play>
    </s:Body>
</s:Envelope>''';
  }

  static String pauseActionXml() {
    return '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<s:Body>
		<u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<InstanceID>0</InstanceID>
		</u:Pause>
	</s:Body>
</s:Envelope>''';
  }

  static String stopActionXml() {
    return '''<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
        </u:Stop>
    </s:Body>
</s:Envelope>''';
  }

  static String getPositionXml() {
    return '''<?xml version="1.0" encoding="utf-8" standalone="no"?>
    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
            <u:GetPositionInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                <InstanceID>0</InstanceID>
                <MediaDuration />
            </u:GetPositionInfo>
        </s:Body>
    </s:Envelope>''';
  }

  static String seekToXml(sk) {
    return '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<s:Body>
		<u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<InstanceID>0</InstanceID>
			<Unit>REL_TIME</Unit>
			<Target>$sk</Target>
		</u:Seek>
	</s:Body>
</s:Envelope>''';
  }
}

/// 设备信息
class DeviceInfo {
  final String baseUrl;
  final String deviceType;
  final String friendlyName;
  final List<dynamic> serviceList;

  DeviceInfo(
      this.baseUrl, this.deviceType, this.friendlyName, this.serviceList);
}

/// 进度解析
class _PositionParser {
  String trackDuration = "00:00:00";
  String trackURI = "";
  String relTime = "00:00:00";
  String absTime = "00:00:00";

  _PositionParser(String text) {
    var doc = XmlDocument.parse(text);
    trackDuration = doc.findAllElements('TrackDuration').first.text;
    trackURI = doc.findAllElements('TrackURI').first.text;
    relTime = doc.findAllElements('RelTime').first.text;
    absTime = doc.findAllElements('AbsTime').first.text;
  }

  String seek(int n) {
    final total = toInt(trackDuration);
    var x = toInt(relTime) + n;
    if (x > total) {
      x = total;
    } else if (x < 0) {
      x = 0;
    }
    return toStr(x);
  }

  static int toInt(String str) {
    final arr = str.split(':');
    var sum = 0;
    for (var i = 0; i < arr.length; i++) {
      sum += int.parse(arr[i]) * (pow(60, arr.length - i - 1) as int);
    }
    return sum;
  }

  static String toStr(int time) {
    final h = (time / 3600).floor();
    final m = ((time - 3600 * h) / 60).floor();
    final s = time - 3600 * h - 60 * m;
    final str = "${z(h)}:${z(m)}:${z(s)}";
    return str;
  }

  static String z(int n) {
    if (n > 9) {
      return n.toString();
    }
    return "0$n";
  }
}

/// xml 解析
class _XmlParser {
  final String text;
  final XmlDocument doc;

  _XmlParser(this.text) : doc = XmlDocument.parse(text);

  DeviceInfo parse(Uri uri) {
    String baseUrl = "";
    try {
      baseUrl = doc.findAllElements('URLBase').first.text;
    } catch (e) {
      baseUrl = uri.origin;
    }
    final deviceType = doc.findAllElements('deviceType').first.text;
    final friendlyName = doc.findAllElements('friendlyName').first.text;
    final serviceList =
        doc.findAllElements('serviceList').first.findAllElements('service');
    final serviceListItems = [];
    for (final service in serviceList) {
      final serviceType = service.findElements('serviceType').first.text;
      final serviceId = service.findElements('serviceId').first.text;
      final controlURL = service.findElements('controlURL').first.text;
      serviceListItems.add({
        "serviceType": serviceType,
        "serviceId": serviceId,
        "controlURL": controlURL,
      });
    }
    return DeviceInfo(baseUrl, deviceType, friendlyName, serviceListItems);
  }
}

/// 设备对象
class Device {
  final DeviceInfo info;

  Device(this.info);

  String get controlURL {
    final base = _removeTrailing("/", info.baseUrl);
    final s = info.serviceList
        .firstWhere((element) => element['serviceId'].contains("AVTransport"));
    if (s != null) {
      final controlURL = _trimLeading("/", s["controlURL"]);
      return '$base/$controlURL';
    }
    throw Exception("not found controlURL");
  }

  Future<String> request(String action, List<int> data) {
    final controlURL = this.controlURL;
    final Map<String, Object> headers = Map.from({
      'SOAPAction': '"urn:schemas-upnp-org:service:AVTransport:1#$action"',
      'Content-Type': 'text/xml',
    });
    return _Http.post(Uri.parse(controlURL), headers, data);
  }

  Future<String> setUrl(String url) {
    final data = _XmlText.setPlayURLXml(url);
    return request('SetAVTransportURI', Utf8Encoder().convert(data));
  }

  Future<String> play() {
    final data = _XmlText.playActionXml();
    return request('Play', Utf8Encoder().convert(data));
  }

  Future<String> pause() {
    final data = _XmlText.pauseActionXml();
    return request('Pause', Utf8Encoder().convert(data));
  }

  Future<String> stop() {
    final data = _XmlText.stopActionXml();
    return request('Stop', Utf8Encoder().convert(data));
  }

  Future<String> seek(String sk) {
    final data = _XmlText.seekToXml(sk);
    return request('Seek', Utf8Encoder().convert(data));
  }

  Future<String> position() {
    final data = _XmlText.getPositionXml();
    return request('GetPositionInfo', Utf8Encoder().convert(data));
  }

  Future<String> seekByCurrent(String text, int n) {
    final p = _PositionParser(text);
    final sk = p.seek(n);
    return seek(sk);
  }
}

/// dlna 解析
class _Parser {
  final String message;

  _Parser(this.message);

  parse() async {
    final lines = message.split('\n');
    final arr = lines.first.split(' ');
    if (arr.length < 3) {
      return;
    }
    final method = arr[0];
    if (method == 'M-SEARCH') {
      // 忽略别人的搜索请求
    } else if (method == 'NOTIFY' ||
        method == "HTTP/1.1" ||
        method == "HTTP/1.0") {
      lines.removeAt(0);
      return await onNotify(lines);
    } else {
      print(message);
    }
  }

  onNotify(List<String> lines) async {
    String uri = '';
    lines.forEach((element) {
      final arr = element.split(':');
      final key = arr[0].trim().toUpperCase();
      if (key == "LOCATION") {
        arr.removeAt(0);
        final value = arr.join(':');
        uri = value.trim();
      }
    });
    if (uri != '') {
      return await getInfo(uri);
    }
  }

  Future<DeviceInfo> getInfo(String uri) async {
    final target = Uri.parse(uri);
    final body = await _Http.get(target);
    final info = _XmlParser(body).parse(target);
    return info;
  }
}

/// 解析 dlna 获取设备信息
class Manager {
  final Map<String, Device> deviceList = {};

  Manager();

  onMessage(String message) async {
    final DeviceInfo? info = await _Parser(message).parse();
    if (info != null) {
      deviceList[info.baseUrl] = Device(info);
    }
  }
}

/// 搜索局域网内支持投屏设备
class Search {
  Timer? sender;
  Timer? receiver;
  RawDatagramSocket? socketServer;
  // 开始扫描局域网可投屏设备
  Future<Manager> start({reusePort = false}) async {
    stop();
    final m = Manager();
    socketServer = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, _UPNP_PORT,
        reusePort: reusePort);
    // https://github.com/dart-lang/sdk/issues/42250 截止到 dart 2.13.4 仍存在问题,期待新版修复
    // 修复IOS joinMulticast 的问题
    if (Platform.isIOS) {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddress.anyIPv4.type,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        final value = Uint8List.fromList(
            _UPNP_AddressIPv4.rawAddress + interface.addresses[0].rawAddress);
        socketServer!.setRawOption(
            RawSocketOption(RawSocketOption.levelIPv4, 12, value));
      }
    } else {
      socketServer!.joinMulticast(_UPNP_AddressIPv4);
    }
    final r = Random();
    final socketClient =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    sender = Timer.periodic(const Duration(seconds: 3), (Timer t) async {
      // 这里的 st 随机没有明白是做什么
      final n = r.nextDouble();
      var st = "ssdp:all";
      if (n > 0.3) {
        if (n > 0.6) {
          st = "urn:schemas-upnp-org:service:AVTransport:1";
        } else {
          st = "urn:schemas-upnp-org:device:MediaRenderer:1";
        }
      }
      _search(socketClient, st);
      final replay = socketClient.receive();
      if (replay == null) {
        return;
      }
      try {
        String message = String.fromCharCodes(replay.data).trim();
        await m.onMessage(message);
      } catch (e) {
        print(e);
      }
    });


    receiver = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
      final d = socketServer!.receive();
      if (d == null) {
        return;
      }
      String message = String.fromCharCodes(d.data).trim();
      // print('Datagram from ${d.address.address}:${d.port}: ${message}');
      try {
        await m.onMessage(message);
      } catch (e) {
        print(e);
      }
    });
    return m;
  }

  /// udp 发送不同协议的搜索信息
  void _search(RawDatagramSocket socket,String st){
    var text = [
      'M-SEARCH * HTTP/1.1',
      'HOST: 239.255.255.250:1900',
      'MAN: "ssdp:discover"',
      'MX: 3',
      'ST: $st',
      '',
      '',
    ].join('\r\n');
    socket.send(text.codeUnits, _UPNP_AddressIPv4, _UPNP_PORT);
  }

  stop() {
    sender?.cancel();
    receiver?.cancel();
    socketServer?.close();
    socketServer = null;
  }
}

/// dlna 服务端播放状态，被投屏端
class _PlayStatus {
  static var playing = false;  // true 播放中，false 暂停或停止
  static bool stopped = true; // true 停止，false 播放或暂停
  static String url = "";
  static String meta = "";
  static int time = 0; //播放进度，单位秒
}

/// dlna 服务端常用 xml 指令 (对dlna 客服端的回复)
class _XmlReplay {
  String ip;
  int port;
  String name;

  _XmlReplay(this.ip, this.port, this.name);

  /// 客户端连接申请回复
  String alive() {
    // GMT example: Thu, 30 Jun 2022 03:29:30 GMT
    var date = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
        .format(DateTime.now());
    var st = 'urn:schemas-upnp-org:device:MediaRenderer:1';
    var resp = [
      'HTTP/1.1 200 OK',
      'CACHE-CONTROL: max-age=60',
      'EXT:',
      'DATE: $date',
      'LOCATION: http://$ip:$port/dlna/info.xml',
      'SERVER: simple flutter dlna server',
      'ST: $st',
      'USN: uuid:$_uuid',
      '',
      '',
    ];
    return resp.join('\r\n');
  }

  /// 服务端设备描述
  String desc() {
    return '''
    <root xmlns="urn:schemas-upnp-org:device-1-0">
    <device>
        <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
        <presentationURL>/</presentationURL>
        <friendlyName>$name</friendlyName>
        <manufacturer>flutter dlna server</manufacturer>
        <manufacturerURL>https://github.com/suconghou/dlna-dart</manufacturerURL>
        <modelDescription>flutter dlna fork from dlna-dart</modelDescription>
        <modelName>flutter dlna</modelName>
        <modelURL>https://github.com/suconghou/dlna-dart</modelURL>
        <UPC>000000000013</UPC>
        <UDN>uuid:$_uuid</UDN>
        <serviceList>
            <service>
                <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
                <SCPDURL>/dlna/Render/AVTransport_scpd.xml</SCPDURL>
                <controlURL>/dlna/_urn:schemas-upnp-org:service:AVTransport_control</controlURL>
                <eventSubURL>/dlna/_urn:schemas-upnp-org:service:AVTransport_event</eventSubURL>
            </service>
        </serviceList>
    </device>
    <URLBase>http://$ip:$port</URLBase>
    </root>''';
  }

  /// 客户端获取播放状态回复
  static String trans() {
    String playState;
    if (_PlayStatus.url.isEmpty) {
      playState = "NO_MEDIA_PRESENT";
    } else {
      playState = _PlayStatus.stopped ? "STOPPED" : "PLAYING";
    }
    return '''<?xml version="1.0" encoding="UTF-8"?>
        <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
          <s:Body>
            <u:GetTransportInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
              <CurrentTransportState>$playState</CurrentTransportState>
              <CurrentTransportStatus>OK</CurrentTransportStatus>
              <CurrentSpeed>1</CurrentSpeed>
            </u:GetTransportInfoResponse>
          </s:Body>
        </s:Envelope>''';
  }

  /// 客户端请求停止播放成功回复
  static String stop() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:StopResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>''';
  }

  /// 客户端请求暂停播放成功回复
  static String pause() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:PauseResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>''';
  }

  /// 客户端请求获取播放媒体信息回复
  static String mediainfo() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
 xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body><u:GetMediaInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
 <NrTracks>0</NrTracks>
 <MediaDuration>02:00:00</MediaDuration>
 <CurrentURI>${_htmlEncode(_PlayStatus.url)}</CurrentURI>
 <CurrentURIMetaData>${_htmlEncode(_PlayStatus.meta)}</CurrentURIMetaData>
 <NextURI></NextURI>
 <NextURIMetaData></NextURIMetaData>
 <PlayMedium>NETWORK</PlayMedium>
 <RecordMedium>NOT_IMPLEMENTED</RecordMedium>
 <WriteStatus>NOT_IMPLEMENTED</WriteStatus>
</u:GetMediaInfoResponse>
</s:Body>
</s:Envelope>''';
  }

  /// 客户端请求获取播放进度回复信息
  static String positionInfo() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:GetPositionInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<Track>0</Track>
			<TrackDuration>02:00:00</TrackDuration>
			<TrackMetaData>${_htmlEncode(_PlayStatus.meta)}</TrackMetaData>
			<TrackURI>${_htmlEncode(_PlayStatus.url)}</TrackURI>
			<RelTime>${_secondToTime(_PlayStatus.time)}</RelTime>
			<AbsTime>${_secondToTime(_PlayStatus.time)}</AbsTime>
			<RelCount>2147483647</RelCount>
			<AbsCount>2147483647</AbsCount>
		</u:GetPositionInfoResponse>
	</s:Body>
</s:Envelope>''';
  }

  /// 设置播放url 成功，即客户端投屏到服务端成功 返回信息
  static String setUriResp() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:SetAVTransportURIResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>''';
  }

  /// 客户端发送播放指令 返回成功信息
  static String playResp() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:PlayResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>''';
  }

  /// 客服端发送拖拽进度 返回成功信息
  static String seekResp() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:SeekResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>''';
  }

  /// 返回错误信息
  // 401	Invalid Action	这个服务中没有这个动作
  // 402	Invalid Args	参数数据错误
  // 403	Out of Sycs	不同步
  // 501	Action Failed	动作执行错误
  // 600 ~ 699	TBD	一般动作错误，有UPnP论坛技术委员会定义
  // 700 ~ 799	TBD	面向标准动作的特定错误，由 UPnP 论坛工作委员会定义
  // 800 ~ 899	TBD	面向非标准动作的特定错误，由 UPnP 厂商定义
  static String error(int errorCode,String errorDescription){
    return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
 <s:Body>
 <u:Fault>
 <faultcode>s:Client</faultcode>
 <faultstring>UPnPError</faultstring>
 <detail>
 <UPnPError xmlns="urn:schemas-upnp-org:control-1-0">
 <errorCode>$errorCode</errorCode>
 <errorDescription>$errorDescription</errorDescription>
 </UPnPError>
 </detail>
 </u:actionNameResponse>
 </s:Body>
</s:Envelope>''';
  }

  /// dlna 服务描述文件
  static String scpd() {
    return '''<?xml version="1.0" encoding="utf-8"?>
          <scpd xmlns="urn:schemas-upnp-org:service-1-0">
            <specVersion>
              <major>1</major>
              <minor>0</minor>
            </specVersion>
            <actionList>
              <action>
                <name>Play</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>Speed</name>
                    <direction>in</direction>
                    <relatedStateVariable>TransportPlaySpeed</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>Stop</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>GetMediaInfo</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>NrTracks</name>
                    <direction>out</direction>
                    <relatedStateVariable>NumberOfTracks</relatedStateVariable>
                    <defaultValue>0</defaultValue>
                  </argument>
                  <argument>
                    <name>MediaDuration</name>
                    <direction>out</direction>
                    <relatedStateVariable>CurrentMediaDuration</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentURI</name>
                    <direction>out</direction>
                    <relatedStateVariable>AVTransportURI</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentURIMetaData</name>
                    <direction>out</direction>
                    <relatedStateVariable>AVTransportURIMetaData</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>NextURI</name>
                    <direction>out</direction>
                    <relatedStateVariable>NextAVTransportURI</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>NextURIMetaData</name>
                    <direction>out</direction>
                    <relatedStateVariable>NextAVTransportURIMetaData</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>PlayMedium</name>
                    <direction>out</direction>
                    <relatedStateVariable>PlaybackStorageMedium</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>RecordMedium</name>
                    <direction>out</direction>
                    <relatedStateVariable>RecordStorageMedium</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>WriteStatus</name>
                    <direction>out</direction>
                    <relatedStateVariable>RecordMediumWriteStatus</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>SetAVTransportURI</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentURI</name>
                    <direction>in</direction>
                    <relatedStateVariable>AVTransportURI</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentURIMetaData</name>
                    <direction>in</direction>
                    <relatedStateVariable>AVTransportURIMetaData</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>GetTransportInfo</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentTransportState</name>
                    <direction>out</direction>
                    <relatedStateVariable>TransportState</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentTransportStatus</name>
                    <direction>out</direction>
                    <relatedStateVariable>TransportStatus</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>CurrentSpeed</name>
                    <direction>out</direction>
                    <relatedStateVariable>TransportPlaySpeed</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>Pause</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>Seek</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>Unit</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_SeekMode</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>Target</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_SeekTarget</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
              <action>
                <name>GetPositionInfo</name>
                <argumentList>
                  <argument>
                    <name>InstanceID</name>
                    <direction>in</direction>
                    <relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>Track</name>
                    <direction>out</direction>
                    <relatedStateVariable>CurrentTrack</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>TrackDuration</name>
                    <direction>out</direction>
                    <relatedStateVariable>CurrentTrackDuration</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>TrackMetaData</name>
                    <direction>out</direction>
                    <relatedStateVariable>CurrentTrackMetaData</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>TrackURI</name>
                    <direction>out</direction>
                    <relatedStateVariable>CurrentTrackURI</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>RelTime</name>
                    <direction>out</direction>
                    <relatedStateVariable>RelativeTimePosition</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>AbsTime</name>
                    <direction>out</direction>
                    <relatedStateVariable>AbsoluteTimePosition</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>RelCount</name>
                    <direction>out</direction>
                    <relatedStateVariable>RelativeCounterPosition</relatedStateVariable>
                  </argument>
                  <argument>
                    <name>AbsCount</name>
                    <direction>out</direction>
                    <relatedStateVariable>AbsoluteCounterPosition</relatedStateVariable>
                  </argument>
                </argumentList>
              </action>
            </actionList>
            <serviceStateTable>
              <stateVariable sendEvents="no">
                <name>TransportState</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>STOPPED</allowedValue>
                  <allowedValue>PAUSED_PLAYBACK</allowedValue>
                  <allowedValue>PLAYING</allowedValue>
                  <allowedValue>TRANSITIONING</allowedValue>
                  <allowedValue>NO_MEDIA_PRESENT</allowedValue>
                </allowedValueList>
                <defaultValue>NO_MEDIA_PRESENT</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>TransportStatus</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>OK</allowedValue>
                  <allowedValue>ERROR_OCCURRED</allowedValue>
                </allowedValueList>
                <defaultValue>OK</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>TransportPlaySpeed</name>
                <dataType>string</dataType>
                <defaultValue>1</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>NumberOfTracks</name>
                <dataType>ui4</dataType>
                <allowedValueRange>
                  <minimum>0</minimum>
                  <maximum>4294967295</maximum>
                </allowedValueRange>
                <defaultValue>0</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentMediaDuration</name>
                <dataType>string</dataType>
                <defaultValue>00:00:00</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>AVTransportURI</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>AVTransportURIMetaData</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>PlaybackStorageMedium</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>NONE</allowedValue>
                  <allowedValue>NETWORK</allowedValue>
                </allowedValueList>
                <defaultValue>NONE</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentTrack</name>
                <dataType>ui4</dataType>
                <allowedValueRange>
                  <minimum>0</minimum>
                  <maximum>4294967295</maximum>
                  <step>1</step>
                </allowedValueRange>
                <defaultValue>0</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentTrackDuration</name>
                <dataType>string</dataType>
                <defaultValue>00:00:00</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentTrackMetaData</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentTrackURI</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>RelativeTimePosition</name>
                <dataType>string</dataType>
                <defaultValue>00:00:00</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>AbsoluteTimePosition</name>
                <dataType>string</dataType>
                <defaultValue>00:00:00</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>NextAVTransportURI</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>NextAVTransportURIMetaData</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>CurrentTransportActions</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>RecordStorageMedium</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>NOT_IMPLEMENTED</allowedValue>
                </allowedValueList>
                <defaultValue>NOT_IMPLEMENTED</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>RecordMediumWriteStatus</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>NOT_IMPLEMENTED</allowedValue>
                </allowedValueList>
                <defaultValue>NOT_IMPLEMENTED</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>RelativeCounterPosition</name>
                <dataType>i4</dataType>
                <defaultValue>2147483647</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>AbsoluteCounterPosition</name>
                <dataType>i4</dataType>
                <defaultValue>2147483647</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="yes">
                <name>LastChange</name>
                <dataType>string</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>A_ARG_TYPE_InstanceID</name>
                <dataType>ui4</dataType>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>A_ARG_TYPE_SeekMode</name>
                <dataType>string</dataType>
                <allowedValueList>
                  <allowedValue>TRACK_NR</allowedValue>
                  <allowedValue>REL_TIME</allowedValue>
                  <allowedValue>ABS_TIME</allowedValue>
                  <allowedValue>ABS_COUNT</allowedValue>
                  <allowedValue>REL_COUNT</allowedValue>
                  <allowedValue>FRAME</allowedValue>
                </allowedValueList>
                <defaultValue>REL_TIME</defaultValue>
              </stateVariable>
              <stateVariable sendEvents="no">
                <name>A_ARG_TYPE_SeekTarget</name>
                <dataType>string</dataType>
              </stateVariable>
            </serviceStateTable>
          </scpd>''';
  }
}

class _Dlna{
   static final Map<String,Device> devices = {};
   static final Map<String,DeviceInfo> infos = {};

  /// 获取所有信息
  static get getInfos => infos;
  /// 获取缓存设备
   static Device? getDevice(String url){
    return devices[url];
  }
}

/// dlna 事件
enum DlnaEvent {
  setUri, play, pause, stop, seek, getPositionInfo
}
///dlna 事件枚举拓展
extension DlnaEventExt on DlnaEvent {
  String get value => ['SetAVTransportURI','Play','Pause','Stop','Seek','GetPositionInfo'][index];
}

class DlnaServer {
  String? _name;

  _ServerListen? _serverListen;

  DlnaServer({String name = ""}){
    _name = name;
  }
  /// 启动dlna 服务
  void start(DlnaAction action) async {
    var ipList = await _getActiveLocalIpList();
    var ip = ipList[0];
    var port = 8888;
    var name = _name;
    if(name == null || name.isEmpty){
      name = "flutter dlna $ip:$port";
    }
    _xmlReplay = _XmlReplay(ip, port, name);

    _Handler(ip,port,action);

    //启动dlna 服务
    _serverListen = _ServerListen();
    _serverListen?.start(ip, port);
  }

  ///停止接收投屏
  void stop() {
    _serverListen?.stop();
  }
}

/// dlna 监听客户端信息
class _ServerListen{
  Timer? _sender;
  Timer? _receiver;
  RawDatagramSocket? _socketServer;

  // 监听客户端信息，并广播自身
  void start(String host,int port,{reusePort = true}) async {
    stop();
    // udp 加入组播网段，监听客户端信息
    _socketServer = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, _UPNP_PORT,
        reusePort: reusePort);
    // https://github.com/dart-lang/sdk/issues/42250 截止到 dart 2.13.4 仍存在问题,期待新版修复
    // 修复IOS joinMulticast 的问题
    if (Platform.isIOS) {
      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddress.anyIPv4.type,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        final value = Uint8List.fromList(
            _UPNP_AddressIPv4.rawAddress + interface.addresses[0].rawAddress);
        _socketServer!.setRawOption(
            RawSocketOption(RawSocketOption.levelIPv4, 12, value));
      }
    } else {
      _socketServer!.joinMulticast(_UPNP_AddressIPv4);
    }
    //广播自身信息
    var serverBroadcast =  _ServerBroadcast(_socketServer!,host,port);
    _sender = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
        serverBroadcast.broadcast();
    });

    // 读取接收信息
    _receiver = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      final d = _socketServer!.receive();
      if (d == null) {
        return;
      }
      String message = String.fromCharCodes(d.data).trim();
      InternetAddress clientAddress = d.address;
      int clientPort = d.port;
      // print('Datagram from ${d.address.address}:${d.port}: ${message}');
      try {
        // 分析接收到的数据
        var serverParser = _ServerParser(message,clientAddress,clientPort,_socketServer!);
        serverParser.get();
      } catch (e) {
        print(e);
      }
    });
  }

  stop() {
    _sender?.cancel();
    _receiver?.cancel();
    _socketServer?.close();
    _socketServer = null;
  }
}

/// dlna 服务端广播信息
class _ServerBroadcast{
  final String _host; // 本机ip
  final int _port; //本机端口
  final RawDatagramSocket _socketServer;
  _ServerBroadcast(this._socketServer,this._host,this._port);

  /// 广播信息
  void broadcast() async {
    _search("ssdp:all");
    _notify("urn:schemas-upnp-org:service:RenderingControl:1");
    _search("urn:schemas-upnp-org:service:AVTransport:1");
    _notify("urn:schemas-upnp-org:service:AVTransport:1");
    _search("urn:schemas-upnp-org:device:MediaRenderer:1");
    _notify("urn:schemas-upnp-org:device:MediaRenderer:1");
    _notify("upnp:rootdevice");
  }

  /// udp 发送不同协议的搜索信息
  void _search(String st){
    var text = [
      'M-SEARCH * HTTP/1.1',
      'HOST: 239.255.255.250:1900',
      'MAN: "ssdp:discover"',
      'MX: 5',
      'ST: $st',
      '',
      '',
    ].join('\r\n');
    _socketServer.send(text.codeUnits, _UPNP_AddressIPv4, _UPNP_PORT);
  }

  /// udp 发送不同协议的通知信息
  void _notify(String nt){
    var text = [
      'NOTIFY * HTTP/1.1',
      'HOST: 239.255.255.250:1900',
      'CACHE-CONTROL: max-age=30',
      'LOCATION: http://$_host:$_port/dlna/info.xml',
      'NT: $nt',
      'NTS: ssdp:alive',
      'SERVER: Python Dlna Server',
      'USN: uuid:$_uuid::$nt',
      '',
      '',
    ].join('\r\n');
    _socketServer.send(text.codeUnits, _UPNP_AddressIPv4, _UPNP_PORT);
  }

}


/// 服务端解析
class _ServerParser{
  final String _message; //客户端发来的数据
  final InternetAddress _clientAddress; //客户端地址
  final int _clientPort; //客户端端口
  final RawDatagramSocket _socket; //socket
  late List<String> _lines;

  _ServerParser(this._message,this._clientAddress,this._clientPort,this._socket){
    final lines = _message.split('\n');
    _lines = lines;
  }

  void get(){
    final arr = _lines.first.split(' ');
    if (arr.length < 3) {
      return;
    }
    // 请求方法
    final method = arr[0].toUpperCase();
    if ( method == "HTTP/1.1" || method == "HTTP/1.0") {
      // 如果是普通get请求，则回应
      mSearch();
    }else if (method == "M-SEARCH"){
      mSearch();
    } else if (method == "NOTIFY"){
      notify();
    }
  }

  /// 收到客户端的搜索请求 （可以原端口返回查询结果，也可以不管，让服务器自己广播）
  void mSearch(){
    var data = _xmlReplay?.alive();
    if(data == null) return;
    _socket.send(data.codeUnits, _clientAddress,_clientPort);
  }

  /// 收到别人（别的可投屏设备）的存活广播
  void notify() async{
    String url = '';
    for (var element in _lines) {
      final arr = element.split(':');
      final key = arr[0].trim().toUpperCase();
      if (key == "LOCATION") {
        url = arr[1].trim();
      }
    }
    if (url != '') {
      getInfo(url);
    }
  }

  /// 请求地址获取设备信息
  void getInfo(String url) async {
    final target = Uri.parse(url);
    final body = await _Http.get(target);
    final deviceInfo = _XmlParser(body).parse(target);
    final device = Device(deviceInfo);
    _Dlna.devices[url] = device;
    _Dlna.infos[url] = deviceInfo;
  }
}

///服务端解析客户端发送来的xml
class _ServerXmlParser{
  final String text;
  final XmlDocument doc;

  _ServerXmlParser(this.text) : doc = XmlDocument.parse(text);

  ///获取客户端的指令
  DlnaEvent? getAction(){
    for (var element in DlnaEvent.values) {
      if(_hasAction(element.value)){
        return element;
      }
    }
    return null;
  }

  ///获取xml 标签内的值
  String getElementText(String element){
    var text = "";
    try {
      text = doc.findAllElements(element).first.text;
    }catch (e){
      print(e);
    }
    return text;
  }

  ///判断 action是否存在
  bool _hasAction(String action){
    String a = action;
    if(!action.startsWith('u:')){
      a ="u:$a";
    }
    return doc.findAllElements(a).isNotEmpty;
  }
}

/// 服务端处理客户端的 http 请求
class _Handler{
  late HttpServer _httpServer;
  late DlnaAction _action;
  /// 开启http服务器
  _Handler(String ip,int port,DlnaAction action) {
    _action = action;
    HttpServer.bind(ip, port).then((value){
      _httpServer = value;
      listen();
    });
  }

  /// 解析客户端http请求
  void listen() async {
    _httpServer.forEach((request) {
      var method = request.method;
      if (method == 'GET'){
        doGet(request);
      }else if (method == 'POST'){
        doPost(request);
      }
    });
  }

  ///处理客户端get请求
  void doGet(HttpRequest request){
    var path = request.uri.path;
    var response  = request.response;
    print(path);

    if (path.startsWith('/info')){
      _info(response);
    } else if (path.startsWith('/dlna/info.xml')){
      _respDesc(response);
    } else if (path.startsWith('/dlna/Render/AVTransport_scpd.xml')){
      _scpd(response);
    } else {
      _error(response);
    }
    response.close();
  }

  ///处理客户端post请求
  void doPost(HttpRequest request) async{
    var path = request.uri.path;
    var response  = request.response;
    ContentType? contentType = request.headers.contentType;
    print(path);
    //if (contentType?.mimeType != 'application/json') return;
    String body;
    _ServerXmlParser? xmlParser;
    DlnaEvent? action;
    try {
      body = await utf8.decoder.bind(request).join();
      print("post content = $body");
      // 解析 post 的内容，获取参数
      if (contentType?.mimeType == 'application/json') { // json 类型
        // dlna 类型基本为xml，json 暂不处理
        return;
      }else if (contentType?.mimeType == 'text/xml'){ //dlna 客户端类型
        // 解析 xml
        xmlParser = _ServerXmlParser(body);
        action = xmlParser.getAction();
      }
    } catch(e){
      response.statusCode = HttpStatus.internalServerError;
      response.write('Exception during file I/O: $e.');
      response.close();
      return;
    }
    if(xmlParser == null) {
      response.close();
      return;
    }
    response.headers.add('Content-type', 'application/json');
    response.headers.add('Access-Control-Allow-Origin', '*');
    String data = "";
    switch (action){
      case DlnaEvent.setUri:
        //获取客户端传来的 uri
        var uri = xmlParser.getElementText('CurrentURI');
        _setUri(uri);
        data = _XmlReplay.setUriResp();
        break;
      case DlnaEvent.play:
        _play();
        data = _XmlReplay.playResp();
        break;
      case DlnaEvent.pause:
        _pause();
        data = _XmlReplay.pause();
        break;
      case DlnaEvent.stop:
        _stop();
        data = _XmlReplay.stop();
        break;
      case DlnaEvent.getPositionInfo:
        _getPosition();
        data = _XmlReplay.positionInfo();
        break;
      case DlnaEvent.seek:
        //获取进度信息
        var sk = xmlParser.getElementText('Target');
        _seek(sk);
        data = _XmlReplay.seekResp();
        break;
      default:
        _error(response);
        response.close();
        return;
    }
    response.write(data);
    response.close();
  }

  ///返回客户端设备信息
  void _info(HttpResponse response){
    response.headers.add('Content-type', 'application/json');
    response.headers.add('Access-Control-Allow-Origin', '*');
    var json = jsonEncode(_Dlna.infos);
    response.write(json);
  }

  ///返回客户端描述文件
  void _respDesc(HttpResponse response){
    response.headers.add('Content-type', 'application/json');
    response.headers.add('Access-Control-Allow-Origin', '*');
    var data = _xmlReplay?.desc() ?? "";
    response.write(data);
  }

  /// 返回客户端服务描述文件
  void _scpd(HttpResponse response){
    response.headers.add('Content-type', 'application/json');
    response.headers.add('Access-Control-Allow-Origin', '*');
    var data = _XmlReplay.scpd();
    response.write(data);
  }

  /// 返回404
  void _error(HttpResponse response){
    response.statusCode = HttpStatus.notFound; //404
    response.headers.add('Content-type', 'application/json');
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.write('404 not found');
  }

  /// 设置播放地址
  void _setUri(String uri){
    _action.setUrl(uri);
    print(uri);
  }
  /// 客户端请求播放视频
  void _play(){
    _action.play();
    _PlayStatus.playing = true;
    _PlayStatus.stopped = false;
  }
  /// 客户端请求暂停视频
  void _pause(){
    _action.pause();
    _PlayStatus.playing = false;
  }
  /// 客户端请求停止视频
  void _stop(){
    _action.stop();
    _PlayStatus.playing = false;
    _PlayStatus.stopped = true;
  }
  /// 客户端请求跳转进度位置
  /// [sk] : 00:00:12
  void _seek(String sk){
    //进度转秒数
    int seek = _PositionParser.toInt(sk);
    _action.seek(seek);
    _PlayStatus.time = seek;
  }
  /// 客户端请求获取服务端进度位置
  void _getPosition(){
    var position = _action.getPosition();
    _PlayStatus.time = position;
  }
}

/// 客户端和服务端交互事件
abstract class DlnaAction {
  void setUrl(String url);
  void play();
  void pause();
  void stop();
  void seek(int position);
  int getPosition(){return _PlayStatus.time;}
}
