# -*- coding:utf-8 -*-
# Atコマンドを突っ込む
# MyGCalModuleとの連携で使う
#
#  @config
#  ~/config.ymlに
#  atmodule:
#    scriptdir: /Users/seijiro/scripts
#    rbdir: /Users/seijiro/code/ruby
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
