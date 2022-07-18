import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// dlna 常用组播地址和端口
const String _UPNP_IP_V4 = '239.255.255.250';
const int _UPNP_PORT = 1900;
final InternetAddress _UPNP_AddressIPv4 = InternetAddress(_UPNP_IP_V4);

/// uuid
const String _uuid = "27d6877e-9527-ea12-abdf-cf8d50e36d54";

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
  var time = Duration(seconds: second).toString();
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
    return request('SetAVTransportURI', const Utf8Encoder().convert(data));
  }

  Future<String> play() {
    final data = _XmlText.playActionXml();
    return request('Play', const Utf8Encoder().convert(data));
  }

  Future<String> pause() {
    final data = _XmlText.pauseActionXml();
    return request('Pause', const Utf8Encoder().convert(data));
  }

  Future<String> stop() {
    final data = _XmlText.stopActionXml();
    return request('Stop', const Utf8Encoder().convert(data));
  }

  Future<String> seek(String sk) {
    final data = _XmlText.seekToXml(sk);
    return request('Seek', const Utf8Encoder().convert(data));
  }

  Future<String> position() {
    final data = _XmlText.getPositionXml();
    return request('GetPositionInfo', const Utf8Encoder().convert(data));
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
      if (kDebugMode) {
        print(message);
      }
    }
  }

  onNotify(List<String> lines) async {
    String uri = '';
    for (var line in lines) {
      final arr = line.split(':');
      final key = arr[0].trim().toUpperCase();
      if (key == "LOCATION") {
        arr.removeAt(0);
        final value = arr.join(':');
        uri = value.trim();
      }
    }
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
    //加入dlna 协议组播
    socketServer!.joinMulticast(_UPNP_AddressIPv4);
    final socketClient =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    sender = Timer.periodic(const Duration(seconds: 3), (Timer t) async {
      // 发送3种不同的搜索协议
      _search(socketClient, "ssdp:all");
      _parseReceiver(socketClient, m);
      _search(socketClient, "urn:schemas-upnp-org:service:AVTransport:1");
      _parseReceiver(socketClient, m);
      _search(socketClient, "urn:schemas-upnp-org:device:MediaRenderer:1");
      _parseReceiver(socketClient, m);
    });
      //接收投屏设备广播的协议
    receiver = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
      _parseReceiver(socketServer!, m);
    });
    return m;
  }

  void _parseReceiver(RawDatagramSocket socket , Manager manager) async {
    // 如果有原路返回的数据则解析
    final replay = socket.receive();
    if (replay == null) {
      return;
    }
    try {
      String message = String.fromCharCodes(replay.data).trim();
      await manager.onMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  /// udp 发送不同协议的搜索信息
  void _search(RawDatagramSocket socket, String st) {
    var text = [
      'M-SEARCH * HTTP/1.1',
      'HOST: 239.255.255.250:1900',
      'MAN: "ssdp:discover"',
      'MX: 3',
      'ST: $st',
      '',
      '',
    ].join('\r\n');
    socket.send(utf8.encode(text), _UPNP_AddressIPv4, _UPNP_PORT);
    //socket.send(text.codeUnits, _UPNP_AddressIPv4, _UPNP_PORT);
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
  static var playing = false; // true 播放中，false 暂停或停止
  static bool stopped = true; // true 停止，false 播放或暂停
  static String url = "";
  static String meta = "";
  static int volume = 30; //音量 0-100
  static int time = 0; //播放进度，单位秒
  static int duration = 0; //视频长度，单位秒
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
    <root xmlns="urn:schemas-upnp-org:device-1-0" xmlns:dlna="urn:schemas-dlna-org:device-1-0">
    <URLBase>http://$ip:$port</URLBase>
    <device>
        <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
        <presentationURL>/</presentationURL>
        <friendlyName>$name</friendlyName>
        <manufacturer>flutter dlna server</manufacturer>
        <manufacturerURL>https://github.com/jarryleo/watch_together.git</manufacturerURL>
        <modelDescription>flutter dlna</modelDescription>
        <modelName>flutter dlna</modelName>
        <modelURL>https://github.com/jarryleo/watch_together.git</modelURL>
        <UPC>000000000011</UPC>
        <UDN>uuid:$_uuid</UDN>
        <dlna:x_dlnadoc xmlns:dlna="urn:schemas-dlna-org:device-1-0">
             DMR-1.50
        </dlna:x_dlnadoc>
        <serviceList>
            <service>
                <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
                <SCPDURL>/dlna/Render/AVTransport_scpd.xml</SCPDURL>
                <controlURL>/dlna/_urn:schemas-upnp-org:service:AVTransport_control</controlURL>
                <eventSubURL>/dlna/_urn:schemas-upnp-org:service:AVTransport_event</eventSubURL>
            </service>
            <service>
                <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
                <SCPDURL>/dlna/Render/AVTransport_scpd.xml</SCPDURL>
                <controlURL>/dlna/_urn:schemas-upnp-org:service:ConnectionManager_control</controlURL>
                <eventSubURL>/dlna/_urn:schemas-upnp-org:service:ConnectionManager_event</eventSubURL>
            </service>
            <service>
                <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
                <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
                <SCPDURL>/dlna/Render/AVTransport_scpd.xml</SCPDURL>
                <controlURL>/dlna/_urn:schemas-upnp-org:service:Rendering_control</controlURL>
                <eventSubURL>/dlna/_urn:schemas-upnp-org:service:Rendering_event</eventSubURL>
            </service>
        </serviceList>
    </device>
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
 <MediaDuration>${_secondToTime(_PlayStatus.duration)}</MediaDuration>
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

  /// 客户端请求获媒体音量信息回复
  static String volume() {
    return '''<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
    <s:Body>
        <u:GetVolumeResponse xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1">
            <CurrentVolume>${_PlayStatus.volume}</CurrentVolume>
        </u:GetVolumeResponse>
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
			<TrackDuration>${_secondToTime(_PlayStatus.duration)}</TrackDuration>
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
  static String error(int errorCode, String errorDescription) {
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

/// dlna 事件
enum DlnaEvent {
  setUri,
  play,
  pause,
  stop,
  seek,
  getPositionInfo,
  getTransportInfo,
  getVolume,
  getMediaInfo
}

///dlna 事件枚举拓展
extension DlnaEventExt on DlnaEvent {
  String get value => [
        'SetAVTransportURI',
        'Play',
        'Pause',
        'Stop',
        'Seek',
        'GetPositionInfo',
        'GetTransportInfo',
        'GetVolume',
        'GetMediaInfo'
      ][index];
}

class DlnaServer {
  String? _name;

  final Map<String,_ServerListen> _serverMap = {};

  DlnaServer({String name = ""}) {
    _name = name;
  }

  /// 启动dlna 服务
  void start(PlayerAction action) async {
    var ipList = await _getActiveLocalIpList();
    var port = 8888;
    var name = _name;
    if (name == null || name.isEmpty) {
      name = "Watch together";
    }
    for (var ip in ipList) {
      _startListenWithIp(ip, port, name, action);
    }
  }

  /// 如果电脑连接了多个网段，开启多个网段服务
  void _startListenWithIp(String ip, int port, String name, PlayerAction action) {
    var xmlReplay = _XmlReplay(ip, port, name);
    _Handler(ip, port, action, xmlReplay);
    //启动dlna 服务
    var serverListen = _ServerListen(xmlReplay);
    _serverMap[ip] = serverListen;
    serverListen.start(ip, port,reusePort: Platform.isIOS);
  }

  ///停止接收投屏
  void stop() {
    for (var server in _serverMap.values) {
      server.stop();
    }
    _serverMap.clear();
  }
}

/// dlna 监听客户端信息
class _ServerListen {
  Timer? _sender;
  Timer? _receiver;
  RawDatagramSocket? _socketServer;
  final _XmlReplay _xmlReplay;

  _ServerListen(this._xmlReplay);

  // 监听客户端信息，并广播自身
  void start(String host, int port, {reusePort = false}) async {
    stop();
    // udp 加入组播网段，监听客户端信息
    _socketServer = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, _UPNP_PORT,
        reusePort: reusePort);
    //加入组播
    _socketServer!.joinMulticast(_UPNP_AddressIPv4);
    //广播自身信息
    var serverBroadcast = _ServerBroadcast(_socketServer!, host, port);
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
        var serverParser =
            _ServerParser(message, clientAddress, clientPort, _socketServer!, _xmlReplay);
        serverParser.get();
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
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
class _ServerBroadcast {
  final String _host; // 本机ip
  final int _port; //本机端口
  final RawDatagramSocket _socketServer;

  _ServerBroadcast(this._socketServer, this._host, this._port);

  /// 广播信息
  void broadcast() async {
    _notify("urn:schemas-upnp-org:service:RenderingControl:1");
    _notify("urn:schemas-upnp-org:service:AVTransport:1");
    _notify("urn:schemas-upnp-org:device:MediaRenderer:1");
    _notify("upnp:rootdevice");
  }

  /// udp 发送不同协议的通知信息
  void _notify(String nt) {
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
    //_socketServer.send(text.codeUnits, _UPNP_AddressIPv4, _UPNP_PORT);
    _socketServer.send(utf8.encode(text), _UPNP_AddressIPv4, _UPNP_PORT);
  }
}

/// 服务端解析
class _ServerParser {
  final String _message; //客户端发来的数据
  final InternetAddress _clientAddress; //客户端地址
  final int _clientPort; //客户端端口
  final RawDatagramSocket _socket; //socket
  late List<String> _lines;
  late final _XmlReplay _xmlReplay;

  _ServerParser(
      this._message,
      this._clientAddress,
      this._clientPort,
      this._socket,
      this._xmlReplay) {
    final lines = _message.split('\n');
    _lines = lines;
  }

  void get() {
    final arr = _lines.first.split(' ');
    if (arr.length < 3) {
      return;
    }
    // 请求方法
    final method = arr[0].toUpperCase();
    if (method == "HTTP/1.1" || method == "HTTP/1.0") {
      // 如果是普通get请求，则回应
      mSearch();
    } else if (method == "M-SEARCH") {
      mSearch();
    }
  }

  /// 收到客户端的搜索请求 （可以原端口返回查询结果，也可以不管，让服务器自己广播）
  void mSearch() {
    var data = _xmlReplay.alive();
    //_socket.send(data.codeUnits, _clientAddress, _clientPort);
    _socket.send(utf8.encode(data), _clientAddress, _clientPort);
  }
}

///服务端解析客户端发送来的xml
class _ServerXmlParser {
  final String text;
  final XmlDocument doc;

  _ServerXmlParser(this.text) : doc = XmlDocument.parse(text);

  ///获取客户端的指令
  DlnaEvent? getAction() {
    for (var element in DlnaEvent.values) {
      if (_hasAction(element.value)) {
        return element;
      }
    }
    return null;
  }

  ///获取xml 标签内的值
  String getElementText(String element) {
    var text = "";
    try {
      text = doc.findAllElements(element).first.text;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return text;
  }

  ///判断 action是否存在
  bool _hasAction(String action) {
    String a = action;
    if (!action.startsWith('u:')) {
      a = "u:$a";
    }
    return doc.findAllElements(a).isNotEmpty;
  }
}

/// 服务端处理客户端的 http 请求
class _Handler {
  late HttpServer _httpServer;
  late PlayerAction _action;
  late _XmlReplay _xmlReplay;

  /// 开启http服务器
  _Handler(String ip, int port, PlayerAction action,_XmlReplay xmlReplay) {
    _action = action;
    _xmlReplay = xmlReplay;
    HttpServer.bind(ip, port).then((value) {
      _httpServer = value;
      listen();
    });
  }

  /// 解析客户端http请求
  void listen() async {
    _httpServer.forEach((request) {
      var method = request.method;
      if (method == 'GET') {
        doGet(request);
      } else if (method == 'POST') {
        doPost(request);
      }
    });
  }

  ///处理客户端get请求
  void doGet(HttpRequest request) {
    var path = request.uri.path;
    var response = request.response;
    if (kDebugMode) {
      print(path);
    }
    if (path.startsWith('/dlna/info.xml')) {
      _respDesc(response);
    } else if (path.startsWith('/dlna/Render/AVTransport_scpd.xml')) {
      _scpd(response);
    } else {
      //兼容用get发送post指令
      doPost(request);
      return;
    }
    response.close();
  }

  ///处理客户端post请求
  void doPost(HttpRequest request) async {
    var path = request.uri.path;
    var response = request.response;
    if (kDebugMode) {
      print(path);
    }
    String body;
    _ServerXmlParser? xmlParser;
    DlnaEvent? action;
    try {
      body = await utf8.decoder.bind(request).join();
      if (kDebugMode) {
        print("client post content = $body");
      }
      // 解析 post 的内容，获取参数
      xmlParser = _ServerXmlParser(body);
      action = xmlParser.getAction();
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Exception during file I/O: $e.');
      response.close();
      return;
    }
    response.headers.add('Content-type', 'text/xml');
    response.headers.add('Access-Control-Allow-Origin', '*');
    String data = "";
    switch (action) {
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
      case DlnaEvent.getTransportInfo:
        data = _XmlReplay.trans();
        break;
      case DlnaEvent.getMediaInfo:
        data = _XmlReplay.mediainfo();
        break;
      case DlnaEvent.getVolume:
        data = _XmlReplay.volume();
        break;
      case DlnaEvent.seek:
        //获取进度信息
        var sk = xmlParser.getElementText('Target');
        _seek(sk);
        data = _XmlReplay.seekResp();
        break;
      default:
        //401	Invalid Action
        data = _XmlReplay.error(401, 'Invalid Action');
        break;
    }
    if (kDebugMode) {
      print("response = $data");
    }
    response.write(data);
    response.close();
  }

  ///返回客户端描述文件
  void _respDesc(HttpResponse response) {
    response.headers.add('Content-type', 'text/xml');
    response.headers.add('Access-Control-Allow-Origin', '*');
    var data = _xmlReplay.desc();
    response.write(data);
  }

  /// 返回客户端服务描述文件
  void _scpd(HttpResponse response) {
    response.headers.add('Content-type', 'text/xml');
    response.headers.add('Access-Control-Allow-Origin', '*');
    var data = _XmlReplay.scpd();
    response.write(data);
  }

  /// 返回404
  void _error(HttpResponse response) {
    response.statusCode = HttpStatus.notFound; //404
    response.headers.add('Content-type', 'text/xml');
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.write('404 not found');
  }

  /// 设置播放地址
  void _setUri(String uri) {
    _PlayStatus.url = uri;
    _action.setUrl(uri);
    if (kDebugMode) {
      print(uri);
    }
  }

  /// 客户端请求播放视频
  void _play() {
    _action.play();
    _PlayStatus.playing = true;
    _PlayStatus.stopped = false;
  }

  /// 客户端请求暂停视频
  void _pause() {
    _action.pause();
    _PlayStatus.playing = false;
  }

  /// 客户端请求停止视频
  void _stop() {
    _action.stop();
    _PlayStatus.playing = false;
    _PlayStatus.stopped = true;
  }

  /// 客户端请求跳转进度位置
  /// [sk] : 00:00:12
  void _seek(String sk) {
    //进度转秒数
    int position = _PositionParser.toInt(sk);
    _action.seek(position);
    _PlayStatus.time = position;
  }

  /// 客户端请求获取服务端进度位置
  void _getPosition() {
    var position = _action.getPosition();
    var duration = _action.getDuration();
    var volume = _action.getVolume();
    _PlayStatus.time = position;
    _PlayStatus.duration = duration;
    _PlayStatus.volume = volume;
    if (kDebugMode) {
      print("position = $position , duration = $duration, volume = $volume");
    }
  }
}

/// 客户端和服务端交互事件
abstract class PlayerAction {

  ///接收客户端投屏过来的播放地址
  void setUrl(String url);

  ///客服端发来 播放指令
  void play();

  ///客户端发来 暂停指令
  void pause();

  ///客户端发来 停止指令
  void stop();

  ///客户端发送seek 指令，播放器 跳转到对应进度
  void seek(int position);

  ///客户端 获取播放进度
  int getPosition();

  ///客户端 获取视频长度
  int getDuration();

  ///客户端 获取视频音量
  int getVolume();
}
