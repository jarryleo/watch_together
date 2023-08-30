///订阅主题
enum ActionTopic {
  join('join'), ///加入,加入后5秒没有收到房主同步信息，则自动创建房间
  play('play'), ///播放
  pause('pause'), ///暂停
  seek('seek'), ///跳转 参数为进度条时间 ，单位秒
  sync('sync'), ///申请同步
  state('state'); ///同步状态，参数 url,isPlaying,position

  final String topic;

  const ActionTopic(this.topic);
}
