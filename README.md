# watch_together


## A project can watch video together on different device.


### ==郑重声明：==
> 1.本项目做为开源项目，不从事商业用途，不盈利；        
> 2.采用GPL3许可证协议，不允许商用；          
> 3.项目初衷是解决异地恋一起看片的需求；          
> 4.项目技术原理：dlna投屏协议，跟投屏到电视原理一致；        
> 5.用户投屏的视频内容与本项目无关，造成的侵权和法律责任由用户自己承担，本项目作者不承担任何责任；   

### 使用方法：
> 1.打开app->输入房间号；                  
> 2.如果显示你是房主，则打开其它视频app，选择你要播放的视频，然后选择投屏->Watch together；                         
> 3.如果你是观众，则自动播放房主的视频，并同步房主的进度；                 
> 4.如果你和房主视频进度不同步，点击界面上的同步按钮即可；

### tips:
> 1.由于各主流视频平台对于投屏协议的收紧，
目前测试只有百度网盘手机app全屏播放时能投屏本app，
开发者可以自行研究其他平台的投屏协议；
> 2.不支持本地视频投屏；
> 3.支持填写视频播放地址；      

本项目 由flutter 编写，支持多平台；           
利用dlna 投屏原理实现多端 异地一起看视频的项目；            

目前支持 android，windows，iphone，ipad，linux；

已测试：android，iphone，Windows；

项目开源，不上架应用市场，安卓用户和windows 用户可以点击下面链接体验: 

[Android下载](https://github.com/jarryleo/watch_together/releases/download/2.0.1/Android_WatchTogether_2.0.1.apk)

[Windows下载](https://github.com/jarryleo/watch_together/releases/download/2.0.1/Windows_WatchTogtherSetup_2.0.1.zip)

ios用户需要自己编译；

### 关于MQTT:

本项目采用mqtt协议，实现多端同步；

mqtt服务器采用[EMQX CLOUD](https://cloud.emqx.com/)免费服务器，每月有1G免费流量，可同时连接1000客户端；

如果流量不够用，可以自己搭建或申请mqtt服务器，修改代码中的mqtt_config的服务器配置即可；

