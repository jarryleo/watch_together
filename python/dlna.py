#!/usr/bin/env python
# encoding: utf-8
import socket
import sys
import re
from functools import lru_cache
import subprocess
import datetime
from random import randint
from urllib import request, parse, error
import struct
import traceback
import _thread
import threading
from socketserver import ThreadingMixIn
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import xml.etree.ElementTree as ET

player = "ffplay.exe -fs" if sys.platform == 'win32' else "ffplay -fs"  # or "mpv -fs"

uuid = "27d6877e-{}-ea12-abdf-cf8d50e36d54".format(randint(1000, 9999))


def getLocalIp():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("119.29.29.29", 80))
    ip = s.getsockname()[0]
    s.close()
    return ip


def htmlEncode(text):
    d = {"&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': '&quot;'}
    for k, v in d.items():
        text = text.replace(k, v)
    return text


@lru_cache(maxsize=8)
def ReqGet(url):
    try:
        try:
            res = request.urlopen(url, timeout=5)
            return res.read()
        except error.HTTPError as e:
            print("request " + url + " error ", e)
            print(e.geturl(), e.read())
            return None
    except Exception as e:
        return None


class Req:
    def __init__(self, headers):
        self.headers = headers

    def post(self, url, values):
        try:
            data = parse.urlencode(values).encode('utf-8')
            req = request.Request(url, data, self.headers, method='POST')
            res = request.urlopen(req, timeout=10)
            return res.read()
        except error.HTTPError as e:
            print(e.geturl(), e.read())
            raise e

    def request(self, controlURL, actionName, data):
        try:
            serviceId = 'urn:schemas-upnp-org:service:AVTransport:1'
            data = data.encode('utf-8')
            self.headers[
                'SOAPAction'] = '"' + serviceId + '#' + actionName + '"'
            self.headers['User-Agent'] = 'UPnP/1.0'
            self.headers['Connection'] = 'close'
            req = request.Request(controlURL,
                                  data,
                                  self.headers,
                                  method='POST')
            res = request.urlopen(req, timeout=10)
            return res.read()
        except error.HTTPError as e:
            print(e.geturl(), e.read())
            raise e


class XmlReplay():
    def __init__(self, ip, port, name):
        self.ip = ip
        self.port = port
        self.name = name

    def alive(self):
        GMT_FORMAT = '%a, %d %b %Y %H:%M:%S GMT'
        date = datetime.datetime.utcnow().strftime(GMT_FORMAT)
        st = 'urn:schemas-upnp-org:device:MediaRenderer:1'
        return '\r\n'.join([
            'HTTP/1.1 200 OK',
            'CACHE-CONTROL: max-age=60',
            'EXT:',
            'DATE: {}'.format(date),
            'LOCATION: http://{}:{}/dlna/info.xml'.format(self.ip, self.port),
            'SERVER: simple python dlna server',
            'ST: {}'.format(st),
            'USN: uuid:{}'.format(uuid),
            '',
            '',
        ])

    def desc(self):
        return '''<root
    xmlns="urn:schemas-upnp-org:device-1-0">
    <device>
        <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
        <presentationURL>/</presentationURL>
        <friendlyName>{}</friendlyName>
        <manufacturer>python dlna server</manufacturer>
        <manufacturerURL>https://github.com/suconghou/dlna-python</manufacturerURL>
        <modelDescription>python dlna</modelDescription>
        <modelName>python dlna</modelName>
        <modelURL>https://github.com/suconghou/dlna-python</modelURL>
        <UPC>000000000013</UPC>
        <UDN>uuid:{}</UDN>
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
    <URLBase>http://{}:{}</URLBase>
</root>'''.format(self.name, uuid, self.ip, self.port)

    def trans(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
        <s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
          <s:Body>
            <u:GetTransportInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
              <CurrentTransportState>{}</CurrentTransportState>
              <CurrentTransportStatus>OK</CurrentTransportStatus>
              <CurrentSpeed>1</CurrentSpeed>
            </u:GetTransportInfoResponse>
          </s:Body>
        </s:Envelope>'''.format(
            'PLAYING' if PlayStatus.stoped ==
                         False else 'STOPED' if PlayStatus.url else 'NO_MEDIA_PRESENT')

    def stop(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:StopResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>'''

    def pause(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:PauseResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>'''

    def mediainfo(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope
 xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body><u:GetMediaInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
 <NrTracks>0</NrTracks>
 <MediaDuration>02:00:00</MediaDuration>
 <CurrentURI>{}</CurrentURI>
 <CurrentURIMetaData>{}</CurrentURIMetaData>
 <NextURI></NextURI>
 <NextURIMetaData></NextURIMetaData>
 <PlayMedium>NETWORK</PlayMedium>
 <RecordMedium>NOT_IMPLEMENTED</RecordMedium>
 <WriteStatus>NOT_IMPLEMENTED</WriteStatus>
</u:GetMediaInfoResponse>
</s:Body>
</s:Envelope>'''.format(htmlEncode(PlayStatus.url),
                        htmlEncode(PlayStatus.meta))

    def postioninfo(self):
        x = randint(1,9)
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:GetPositionInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<Track>0</Track>
			<TrackDuration>02:00:00</TrackDuration>
			<TrackMetaData></TrackMetaData>
			<TrackURI>{}</TrackURI>
			<RelTime>00:00:0{}</RelTime>
			<AbsTime>00:00:0{}</AbsTime>
			<RelCount>2147483647</RelCount>
			<AbsCount>2147483647</AbsCount>
		</u:GetPositionInfoResponse>
	</s:Body>
</s:Envelope>'''.format(htmlEncode(PlayStatus.url),x,x)

    def setUriResp(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:SetAVTransportURIResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>'''

    def playresp(self):
        return '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
	<s:Body>
		<u:PlayResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
	</s:Body>
</s:Envelope>'''

    def seekresp(self):
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body><u:SeekResponse xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\"></u:SeekResponse></s:Body></s:Envelope>"

    def scpd(self):
        AVTransport_SCPD = \
            '''<?xml version="1.0" encoding="utf-8"?>
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
          </scpd>'''
        return AVTransport_SCPD


class XmlText():
    def setPlayURLXml(self, url):
        # 斗鱼tv的dlna server,只能指定直播间ID,必须是如下格式
        title = url
        douyu = re.match(r"^https?://(\d+)\?douyu$", url)
        if douyu:
            roomId = douyu.group(1)
            title = "roomId = {}, line = 0".format(roomId)
        meta = '''<DIDL-Lite
    xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"
    xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:sec="http://www.sec.co.kr/">
    <item id="false" parentID="1" restricted="0">
        <dc:title>{}</dc:title>
        <dc:creator>unkown</dc:creator>
        <upnp:class>object.item.videoItem</upnp:class>
        <res resolution="4"></res>
    </item>
</DIDL-Lite>
'''.format(title)
        return '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
   <s:Body>
      <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
         <InstanceID>0</InstanceID>
         <CurrentURI>{}</CurrentURI>
         <CurrentURIMetaData>{}</CurrentURIMetaData>
      </u:SetAVTransportURI>
   </s:Body>
</s:Envelope>'''.format(htmlEncode(url), htmlEncode(meta))

    def playActionXml(self):
        return '''<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Speed>1</Speed>
        </u:Play>
    </s:Body>
</s:Envelope>
        '''

    def pauseActionXml(self):
        return '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<s:Body>
		<u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<InstanceID>0</InstanceID>
		</u:Pause>
	</s:Body>
</s:Envelope>
    '''

    def stopActionXml(self):
        return '''<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
        </u:Stop>
    </s:Body>
</s:Envelope>
        '''

    def getPositionXml(self):
        return '''<?xml version="1.0" encoding="utf-8" standalone="no"?>
    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
            <u:GetPositionInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                <InstanceID>0</InstanceID>
                <MediaDuration />
            </u:GetPositionInfo>
        </s:Body>
    </s:Envelope>
        '''

    def seekToXml(self, sk):
        return '''<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<s:Body>
		<u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
			<InstanceID>0</InstanceID>
			<Unit>REL_TIME</Unit>
			<Target>{}</Target>
		</u:Seek>
	</s:Body>
</s:Envelope>
        '''.format(sk)


class xmlReqParser:
    def __init__(self, data):
        self.data = data

    def CurrentURI(self):
        root = ET.fromstring(self.data)
        namespaces = {'s': 'http://schemas.xmlsoap.org/soap/envelope/'}
        value = root.findtext('s:Body//CurrentURI', None, namespaces)
        return value

    def CurrentURIMetaData(self):
        root = ET.fromstring(self.data)
        namespaces = {'s': 'http://schemas.xmlsoap.org/soap/envelope/'}
        value = root.findtext('s:Body//CurrentURIMetaData', None, namespaces)
        return value


class xmlParser:
    def __init__(self, url, data):
        self.url = url
        self.data = data

    def parse(self):
        r = parse.urlparse(self.url)
        URLBase = r.scheme + '://' + str(r.hostname) + ':' + str(r.port)
        device = {}
        info = {
            'URLBase': URLBase,
            'device': device,
        }
        root = ET.fromstring(self.data)
        for child in root:
            tag = child.tag.split('}').pop()
            if tag == 'device':
                for d in child:
                    key = d.tag.split('}').pop()
                    if key == 'deviceType':
                        device['deviceType'] = d.text
                    elif key == 'friendlyName':
                        device['friendlyName'] = d.text
                    elif key == 'serviceList':
                        serviceList = []
                        for service in d:
                            serviceItem = {}
                            for sitem in service:
                                kk = sitem.tag.split('}').pop()
                                serviceItem[kk] = sitem.text
                            serviceList.append(serviceItem)
                        device['serviceList'] = serviceList
                    else:
                        pass  # print('ignore device tag ', key)
            else:
                pass  # print('ignore tag ', tag)
        info['device'] = device
        return info


class Device:
    def __init__(self, info):
        self.info = info
        self.header = {"Content-Type": "text/xml"}

    def url(self):
        part = ''
        for item in self.info['device']['serviceList']:
            if 'org:service:AVTransport' in item['serviceType']:
                part = item['controlURL']
        return parse.urljoin(self.info['URLBase'], part)

    def setPlayUrl(self, url):
        controlURL = self.url()
        data = XmlText().setPlayURLXml(url)
        return Req(self.header).request(controlURL, 'SetAVTransportURI', data)

    def play(self, ):
        controlURL = self.url()
        data = XmlText().playActionXml()
        return Req(self.header).request(controlURL, 'Play', data)

    def pause(self):
        controlURL = self.url()
        data = XmlText().pauseActionXml()
        return Req(self.header).request(controlURL, 'Pause', data)

    def stop(self):
        controlURL = self.url()
        data = XmlText().stopActionXml()
        return Req(self.header).request(controlURL, 'Stop', data)

    def seek(self, sk):
        controlURL = self.url()
        data = XmlText().seekToXml(sk)
        return Req(self.header).request(controlURL, 'Seek', data)

    def getPosition(self):
        controlURL = self.url()
        data = XmlText().getPositionXml()
        return Req(self.header).request(controlURL, 'GetPositionInfo', data)


class parser:
    def __init__(self, data, address, udp_socket):
        self.address = address
        self.lines = data.splitlines()
        self.udp_socket = udp_socket

    def get(self):
        arr = self.run_method()
        if arr == None or len(arr) != 3:
            return '', {}, None
        return arr

    def run_method(self):
        method, path, version = self.lines[0].split(' ')
        method = str(method.replace('-', '')).upper()
        self.lines = self.lines[1:]
        if not hasattr(self, method):
            if method == "HTTP/1.1" or method == "HTTP/1.0":
                return self.NOTIFY()
            print("method not found", method, path, version)
            return
        return getattr(self, method)()

    # 收到别人的查询消息
    def MSEARCH(self):
        data = xmlreplayer.alive()
        if self.udp_socket is None:
            self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.udp_socket.setblocking(False)
        self.udp_socket.sendto(data.encode(), self.address)

    # 别人发出了存活广播,我们在此过滤投屏设备
    def NOTIFY(self):
        for line in self.lines:
            arr = line.split(':', 1)
            if len(arr) != 2:
                continue
            key = arr[0].strip().upper()
            value = arr[1].strip()
            if key == "LOCATION":
                return self.getInfo(value)

    def getInfo(self, url):
        data = ReqGet(url)
        if data is None:
            return
        info = xmlParser(url, data).parse()
        return url, info, Device(info)


class ListenWorker(threading.Thread):
    def __init__(self, onfound):
        threading.Thread.__init__(self)
        self.daemon = True
        self.onfound = onfound

    def run(self):
        self.search()
        self.listen()

    def listen(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM,
                          socket.IPPROTO_UDP)
        # 允许端口复用
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP, 0)
        # 绑定监听多播数据包的端口
        s.bind(('0.0.0.0', 1900))
        # 声明该socket为多播类型
        s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 255)
        # 加入多播组，组地址由第三个参数制定
        mreq = struct.pack("4sl", socket.inet_aton('239.255.255.250'),
                           socket.INADDR_ANY)
        s.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
        while True:
            try:
                data, address = s.recvfrom(2048)
                self.parse(data, address, None)
            except Exception as e:
                traceback.print_exc()

    def parse(self, data, address, udp_socket):
        url, info, item = parser(data.decode(), address, udp_socket).get()
        if url != '' and item != None:
            self.onfound(url, info, item)

    def search(self):
        def ondata(data, address, udp_socket):
            try:
                self.parse(data, address, udp_socket)

            except Exception as e:
                traceback.print_exc()

        SearchWorker(ondata).start()


class SearchWorker(threading.Thread):
    def __init__(self, ondata):
        threading.Thread.__init__(self)
        self.daemon = True
        self.ondata = ondata
        self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.udp_socket.setblocking(False)
        self.udp_socket.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP,
                                   0)

    def run(self):
        while True:
            self.search("ssdp:all")
            self.sendNotify("urn:schemas-upnp-org:service:RenderingControl:1")
            self.search("urn:schemas-upnp-org:service:AVTransport:1")
            self.sendNotify("urn:schemas-upnp-org:service:AVTransport:1")
            self.search("urn:schemas-upnp-org:device:MediaRenderer:1")
            self.sendNotify("urn:schemas-upnp-org:device:MediaRenderer:1")
            self.sendNotify("upnp:rootdevice")

    def sendUdp(self, data):
        try:
            udp_socket = self.udp_socket
            udp_socket.sendto(data.encode(), ('239.255.255.250', 1900))
            time.sleep(1)
            data, address = udp_socket.recvfrom(2048)
            self.ondata(data, address, udp_socket)
        except BlockingIOError as e:
            pass

    def search(self, st):
        text = '\r\n'.join([
            'M-SEARCH * HTTP/1.1',
            'HOST: 239.255.255.250:1900',
            'MAN: "ssdp:discover"',
            'MX: 5',
            'ST: {}'.format(st),
            '',
            '',
        ])
        self.sendUdp(text)

    def sendNotify(self, nt):
        text = '\r\n'.join([
            'NOTIFY * HTTP/1.1',
            'HOST: 239.255.255.250:1900',
            'CACHE-CONTROL: max-age=30',
            'LOCATION: http://{}:{}/dlna/info.xml'.format(localIp, host[1]),
            'NT: {}'.format(nt),
            'NTS: ssdp:alive',
            'SERVER: Python Dlna Server',
            'USN: uuid:{}::{}'.format(uuid, nt),
            '',
            '',
        ])
        self.sendUdp(text)


class Dlna:
    def __init__(self):
        self.devices = {}
        self.infos = {}

    def start(self):
        ListenWorker(self.onFound).start()

    def onFound(self, url, info, item):
        self.infos[url] = info
        self.devices[url] = item

    def getInfos(self):
        return self.infos

    def getDevice(self, url):
        return self.devices.get(url)


class ThreadingSimpleServer(ThreadingMixIn, HTTPServer):
    pass


class PlayStatus:
    playing = None
    stoped = True
    url = ""
    meta = ""

# http 服务器处理类
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            req = parse.urlparse(self.path)
            path = req.path
            query = parse.parse_qs(req.query)
            if path.startswith('/info'):
                return self.info(query)
            if path.startswith('/dlna/info.xml'):
                return self.respdesc()
            if path.startswith('/dlna/Render/AVTransport_scpd.xml'):
                return self.scpd()

            return self.index()
        except Exception as e:
            traceback.print_exc()
            self.send_error(500, str(e), str(e))

    def do_POST(self):
        try:
            req = parse.urlparse(self.path)
            path = req.path
            query = parse.parse_qs(req.query)
            if path.startswith('/play'):
                return self.play(query)
            if path.startswith('/pause'):
                return self.pause(query)
            if path.startswith('/stop'):
                return self.stop(query)
            if path.startswith('/position'):
                return self.position(query)
            if path.startswith('/seek'):
                return self.seek(query)
            if path.startswith(
                    '/dlna/_urn:schemas-upnp-org:service:AVTransport_control'):
                body = self.rfile.read(int(self.headers['content-length']))
                return self.execPlay(body.decode())

            return self.notfound()
        except Exception as e:
            traceback.print_exc()
            self.send_error(500, str(e), str(e))

    def do_SUBSCRIBE(self):
        print(self.headers)
        print('do_SUBSCRIBE')
        self.send_response(200)
        self.send_header('TIMEOUT', 'Second-3600')
        self.send_header('SID', 'uuid:f392-a153-571c-e10b')
        self.send_header('Content-Length', '0')
        self.end_headers()

    def respdesc(self):
        data = xmlreplayer.desc()
        self.send_response(200)
        self.send_header('Content-type', 'text/xml')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(data.encode())

    def scpd(self):
        data = xmlreplayer.scpd()
        self.send_response(200)
        self.send_header('Content-type', 'text/xml')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(data.encode())

    def execPlay(self, data):
        if 'GetTransportInfo' in data:
            data = xmlreplayer.trans()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:Stop' in data:
            if PlayStatus.playing:
                PlayStatus.playing.kill()
                PlayStatus.stoped = True
                print('local stop ', PlayStatus.url)
            data = xmlreplayer.stop()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:Pause' in data:
            data = xmlreplayer.pause()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:Play' in data:
            data = xmlreplayer.playresp()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')

            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:Seek' in data:
            data = xmlreplayer.seekresp()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:GetMediaInfo' in data:
            data = xmlreplayer.mediainfo()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        if 'u:GetPositionInfo' in data:
            data = xmlreplayer.postioninfo()
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data.encode())
            return
        reqParser = xmlReqParser(data)
        url = reqParser.CurrentURI()
        meta = reqParser.CurrentURIMetaData()
        if url is None:
            print(self.headers)
            print(data)
            self.notfound()
            return
        print('local play ', url)
        ret = subprocess.Popen('{} "{}"'.format(player, url), shell=True)
        print(ret)
        if PlayStatus.playing:
            PlayStatus.playing.kill()
        PlayStatus.playing = ret  # type: ignore
        PlayStatus.stoped = False
        PlayStatus.url = url
        PlayStatus.meta = meta or ""
        data = xmlreplayer.setUriResp()
        self.send_response(200)
        self.send_header('Content-type', 'text/xml')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(data.encode())

    def index(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        with open("index.html", "rb") as f:
            self.wfile.write(f.read())

    def notfound(self):
        self.send_response(404)
        self.send_header('Content-type', 'text/plain')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(b'404 not found')

    def info(self, query):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(dlna.getInfos()).encode())

    def play(self, query):
        url = query.get('url')
        if url is None:
            return self.err('error params')
        url = url[0]
        device = dlna.getDevice(url)
        if device is None:
            return self.err('no device')
        playUrl = query.get('playUrl')
        if playUrl is None or playUrl[0] is None:
            # recover play
            ret = device.play()
            self.ok(ret.decode())
            return
        playUrl = playUrl[0]
        print('remote play ', playUrl)
        ret = device.setPlayUrl(playUrl)
        device.play()
        return self.ok(ret.decode())

    def pause(self, query):
        url = query.get('url')
        if url is None:
            return self.err('error params')
        url = url[0]
        device = dlna.getDevice(url)
        if device is None:
            return self.err('no device')
        ret = device.pause()
        return self.ok(ret.decode())

    def stop(self, query):
        url = query.get('url')
        if url is None:
            return self.err('error params')
        url = url[0]
        device = dlna.getDevice(url)
        if device is None:
            return self.err('no device')
        ret = device.stop()
        return self.ok(ret.decode())

    def position(self, query):
        url = query.get('url')
        if url is None:
            return self.err('error params')
        url = url[0]
        device = dlna.getDevice(url)
        if device is None:
            return self.err('no device')
        ret = device.getPosition()
        return self.ok(ret.decode())

    def seek(self, query):
        url = query.get('url')
        if url is None:
            return self.err('error params')
        url = url[0]
        sk = query.get('seek')
        if sk is None:
            return self.err('error params')
        sk = sk[0]
        device = dlna.getDevice(url)
        if device is None:
            return self.err('no device')
        ret = device.seek(sk)
        return self.ok(ret.decode())

    def err(self, err):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({'code': -1, 'msg': err}).encode())

    def ok(self, msg):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({'code': 0, 'msg': msg}).encode())


if __name__ == '__main__':
    try:
        localIp = getLocalIp()
        host = (localIp, 8888)
        xmlreplayer = XmlReplay(localIp, host[1],
                                "dlna({}:{})".format(localIp, host[1]))
        dlna = Dlna()
        dlna.start()
        server = ThreadingSimpleServer(host, Handler)

        def local(ip, port):
            ThreadingSimpleServer((ip, port), Handler).serve_forever()

        _thread.start_new_thread(local, ('127.0.0.1', host[1]))
        print("Starting server, listen at: %s:%s" % host)
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit()