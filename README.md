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

本项目 利用dlna 投屏原理实现多端 异地一起看视频的项目；
flutter 编写，支持多平台；

目前支持 android，windows，iphone，ipad，linux；

已测试：android，iphone，Windows；

项目开源，不上架应用市场，安卓用户和windows 用户可以点击下面链接体验；

安卓安装包下载：
[Download Android watch_together_1.0.1.apk](https://github.com/jarryleo/watch_together/releases/download/1.0.1/watch_together_1.0.1.apk)    

windows 安装包下载：
[Download Windows installer WatchTogether.zip](https://github.com/jarryleo/watch_together/releases/download/1.0.1/WatchTogther.zip)


有自己服务器的开发者，自己部署服务端，修改客户端内的服务器ip即可；

选择 tcp 分支：

[https://github.com/jarryleo/WatchTogetherServer.git](https://github.com/jarryleo/WatchTogetherServer/tree/tcp)