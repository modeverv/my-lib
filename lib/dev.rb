# -*- coding:utf-8 -*-

#! ruby
# -*- coding: utf-8 -*-
#
# 俺俺な典型的な動作を提供する
#
# こんな感じで使うと良い
# 
#  require "/Users/seijiro/code/ruby/my-lib.rb"
#  class This < MyObject
#    include RunPerSecModule
#    include MyDBModule
#    include MyPusherModule
#  .....
#
#  end
#

# 俺俺インスタンスをつくるためにクラスを用意した
# 典型的なrequireを書きこんでいく
# 読み込み済みモジュール
#   kconv time
class MyObject
  def self.myrequire
    require "kconv"
    require "time"
    require "optparse"
  end
end

#~/config.ymlに配置された設定ファイルを読んで返す
class MyConfig
  # 設定オブジェクトを返す
  def self.get
    self.read unless @data
    return @data
  end

  private

  def self.read
    require 'yaml'
    @data = YAML.load_file("#{ENV['HOME']}/config.yml")
  end
end

# 指定秒数ごとにrun関数をループする
# 各メソッドを必要に応じて再定義して使う。
#
#   使い方:
#   someinstance.extend RunPerSecModule
#   someinstance.run(ループのインターバルsec){
#     __block__for__yield__
#   }
#   
# OR
#   
#   class ThisDo < MyObject
#     include RunPerSecModule
#   .....
# 
module RunPerSecModule
  # ループフラグ
  @loop_flg

  # main_loopをループする
  #   sec : ループ間隔 秒
  # before_run_loop,ループ,after_run_loopの順番で実行する。
  # ループの中身はloop_hook_pre,与えられたブロック,main_loop,loop_hook_postの順番で実行する
  def run(sec)
	init_run_per_sec_module
	before_run_loop
	while @loop_flg
	  loop_hook_pre
	  yield
	  main_loop
	  loop_hook_post
	  sleep sec
	end
	after_run_loop
  end

  # 外からは使わない
  # 無限ループフラグを立てる
  def init_run_per_sec_module
	@loop_flg = true
  end

  # runのループを止める
  def stop_run
    @loop_flg = false
  end
  
  # runメソッドが呼ばれるとループの前に一回だけ実行される
  def before_run_loop
  end

  # runメソッドのloopの中で最初に実行される
  def loop_hook_pre
  end

  # runメソッドのloopの中で実行される
  def main_loop
  end

  # runのループの中でmain_loopのあとで実行される
  def loop_hook_post
  end
  
  # runメソッドが呼ばれるとループのあとで実行される
  def after_run_loop
  end
end

# DBに接続してなんでもいれておくtableへのインサートを提供する
#
# @dbcon:ＤＢコネクション
# @insert:インサート文
# @config:
#    ~/config.ymlに
#    mydbmodule:
#      server:localhost
#      port: 3389
#      socket:/tmp/mysql.sock
#      user:xxxx
#      pass:xxxxxx
#      database:xxxxx
#  を設定
#
# 使い方
# class ThisDo
# include MyDBModule
# して
#  o = ThisDo.new
#  o.insert_DB("my_app_tail",'data')
# でOK
#
module MyDBModule
  #DBコネクション
  @dbcon

  #インサート文
  @insert

  # DBに接続する
  def set_my_db
	require "mysql"
    @c = MyConfig.get
	@dbcon = Mysql::new(
      @c['mydbmodule']['server'],
      @c['mydbmodule']['user'],
      @c['mydbmodule']['pass'],
      @c['mydbmodule']['database'],
      @c['mydbmodule']['port'],
      @c['mydbmodule']['socket'],
      )
	@dbcon.query("set character set utf8") #おまじない
	@dbcon.query("use " + @c['mydbmodule']['database'])
	@insertsql = @dbcon.prepare("insert into keyvalue(`usage`,`value`) values (?,?);")
  end

  # テーブルにインサートする
  #
  #   args
  #   usage : string key
  #   value : string value
  def insert_DB(key='test_app',value='')
    set_my_db if @dbcon == nil
	@insertsql.execute(key,value)
  end
end

# Pusherサービスへのアクセスを提供する
# https://app.pusherapp.com/apps/7449/api_access?welcome=true
#  @pusher_app_id = 'your pusher app id'
#  @pusher_key = 'pusher key'
#  @pusher_secret = 'pusher secret'
#  @config
#  ~/config.ymlに
#  mypushermodule:
#    app_id:xxx
#    key:xxxxxxxxxxxxx
#    secret:xxxxxxxxxx
#    event:my_event
#    channel:test_channel
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
    @pusher_channel = @c['test_channel']
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
end	


# Googleカレンダーへのアクセスを提供する
#
# ~/config.ymlに
#  gmail:
#    address:YourMailAdress@gmail.com
#    pass:xxxxxxxxxx
#    feedurl:http://www.google.com/calendar/feeds/xxxxxxxx%40gmail.com/private/full
#
# 使い方など
# class ThisDo
#   include MyGCalModule
# して
# o = ThisDo.new
# o.gcal_read
# とかでok
module MyGCalModule
  attr_accessor :gmail,:gmailpass,:gcalfeedurl,:gcal_query
  
  def gcal_read
    service
    @gcal_events = @gcal.events
    return self
  end

  #GCalへ書きこむ
  def gcal_write(eventdata)
    service
    event = @gcal.create_event
    event.title = eventdata[:title]
    event.st = eventdata[:start]
    event.en = eventdata[:end]
    event.save!
    @gcal_event = event
    return self
  end

  # gcalのイベントをAtMduleが食べれる形に変換する
  # 共通のJOBクラスで包もうかしら?
  def gcal_parse_2_jobs
    @gcal_jobs = []
    q = @gcal_query ||= '[Gcal2PusherTail'
    @gcal_events.each do |event|
      begin
        kind,filename = event.title.split(']')
        if(kind == @gcal_query && filename != nil)
          @gcal_jobs << {:filename => filename,
            :start => event.st,
            :end => event.en,
            :object => event}
        end
      rescue =>ex
        p ex
        #握りつぶす
      end
    end
    return self
  end

  #fetchしたデータの取り込み済みマークを立てる
  def gcal_checkout(event)
    event.title = '[FETCHED]' + event.title
    event.save!
    return self
  end

  # GCalへのアクセス
  def service
    if @gcal_srv.nil?
      require 'gcalapi'
      @c = MyConfig.get['gmail']
      @gcal_srv = GoogleCalendar::Service.new(@c['address'],@c['pass'])
    end
    @gcal = GoogleCalendar::Calendar::new(@gcal_srv, @c['feedurl'])
  end
end

# Atコマンドを突っ込む
# MyGCalModuleとの連携で使う
#
#  @config
#  ~/config.ymlに
#  atmodule:
#    scriptdir:/Users/seijiro/scripts
#    rbdir:/Users/seijiro/code/ruby
#
# 使い方など
# class ThisDo
#   include MyAtModule
#   include MyGCalModule
# して
# o = ThisDo.new
# とかでok
module MyAtModule
  def initialize
    @c = MyConfig.get['atmodule']
  end
  
  def gcaljobs_2_at
    @gcal_jobs.each { |job| jobs2at(job) }
    return self
  end

  def jobs2at(job)
    command = _at_command(job)
    File.open("#{_at_scriptpath(job)}","w") do |io|
      io.write(command)
    end

    atcommand =  "/usr/bin/at -f #{_at_scriptpath(job)} #{job[:start].localtime.strftime("%H:%M %m/%d/%y")}"
    p atcommand
    p command
    system atcommand
    gcal_checkout(job[:object])
  end

  def _at_scriptpath(job)
    "#{@c['scriptdir']}/job2at_#{job[:start].localtime.strftime("%Y%m%d%H%M")}.sh"
  end

  def _at_command(job)
    "#! /bin/bash
#ユーザーの環境変数パスを使いたい
source ~/.bashrc
growlnotify -t 'Gcal2At' -m 'pusher tail #{job[:filename]} start . end is #{job[:start].localtime.strftime("%Y/%m/%d/%H/%M")}'
ruby #{@c['rbdir']}/pushertail.rb #{job[:filename]} '#{job[:end].to_s}'
"
  end
end



__END__
test
