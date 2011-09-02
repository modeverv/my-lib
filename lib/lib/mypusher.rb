# Pusherサービスへのアクセスを提供する
# https://app.pusherapp.com/apps/7449/api_access?welcome=true
#  @pusher_app_id = 'your pusher app id'
#  @pusher_key = 'pusher key'
#  @pusher_secret = 'pusher secret'
#  @config
#  ~/config.ymlに
#  mypushermodule:
#    app_id: xxx
#    key: xxxxxxxxxxxxx
#    secret: xxxxxxxxxx
#    event: my_event
#    channel: test_channel
#
# 使い方など
# class ThisDo
#   include MyPusherModule
# して
# o = ThisDo.new
# o.push_pusher('test_app','test')
# とかでok
module MyPusherModule
  
  #pussherが設定されているか？
  @pusherconnected

  # Pusherへの接続を設定する
  def set_my_pusher
    @c = MyConfig.get['mypushermodule']
	require "pusher"
	Pusher.app_id = @c['app_id']
	Pusher.key = @c['key']
	Pusher.secret = @c['secret']
    @pusher_event = @c['event']
    @pusher_channel = @c['channel']
    p @c
  end

  # Pusherにデータをpushする
  #   args
  #   app_name : string アプリの名前
  #   data     : string データ
  def push_pusher(app_name='test_app',data='test')
	if @pusherconnected == nil
      set_my_pusher
      @pusherconnected = true
	end
	begin
	  Pusher[@pusher_channel].trigger!(
        @pusher_event, { app_name => data})
	rescue Pusher::Error => e
	  p e  
	end
  end

  def get_puhser_html
    return <<-"EOT"
<!DOCTYPE html>
<head>
  <title>PusherTail</title>
  <script src="http://js.pusherapp.com/1.8/pusher.min.js"></script>
  <script>
    // Enable pusher logging - don't include this in production
    Pusher.log = function(message) {
      if (window.console && window.console.log) window.console.log(message);
    };

    // Flash fallback logging - don't include this in production
    WEB_SOCKET_DEBUG = true;
    var pusher = new Pusher('#{ @c['key']}');
    var channel = pusher.subscribe('#{ @c['channel']}');
    channel.bind('#{ @c['event']}', function(data) {
       hoge = document.getElementById("main").innerHTML;
       document.getElementById("main").innerHTML = data['#{ @c['app_name']}'] + "<hr>" + hoge;
    });
  </script>
</head>
<body>
  work at Chrome
  <div id="main">&nbsp;</div>
</body>
EOT
  end

end	
