# DBに接続してなんでもいれておくtableへのインサートを提供する
#
# @dbcon:ＤＢコネクション
# @insert:インサート文
# @config:
#    ~/config.ymlに
#    mydbmodule:
#      server: localhost
#      port: 3389
#      socket: /tmp/mysql.sock
#      user: xxxx
#      pass: xxxxxx
#      database: xxxxx
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
