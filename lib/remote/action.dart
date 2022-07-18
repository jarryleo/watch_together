
/// 执行动作 [] 客户端发送专属信息 {} 服务端发送专属信息 ，其它为播放器通用信息
/// url,play,pause,seek, 播放器指令
/// [heartbeat 只有房主心跳同步播放状态,join 加入房间或者创建,sync 请求同步房主进度],
/// {idle 新房间}
/// exit 退出房间/解散房间
enum Action {
  join,         //客户端申请加入或者创建房间
  exit,         //客户端退出房间，客户端是房主则解散房间
  idle,         //返回客户端房间空闲指令，表示客户端为房主
  sync,         //客户端请求同步视频进度
  heartbeat,    //客户端心跳，保持网络连接活跃
  url,          //房主开播，设置视频播放地址，同步给所有客户端
  play,         //房主点击播放，同步给所有客户端
  pause,        //房主点击暂停，同步给所有客户端
  seek          //房主拖动进度，同步给所有客户端
}

extension ActionExt on Action {
  String get value => [
    'join',
    'exit',
    'idle',
    'sync',
    'heartbeat',
    'url',
    'play',
    'pause',
    'seek'
  ][index];
}
