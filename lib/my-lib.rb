#-*- coding:utf-8 -*-

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

# make String Colored
require 'rubygems'
require 'term/ansicolor'
class String
  include Term::ANSIColor
end

# MyObject
require 'lib/myobject.rb'
# MyConfig
require 'lib/myconfig.rb'
# MyLogger
require 'lib/mylogger.rb'
# Job
require 'lib/job'
# MyMachine
require 'lib/machine.rb'
# MyJobAnisoku
require 'lib/anisoku.rb'
# RunPerSecModule
require 'lib/runpersec.rb'
# MyDBModule
require 'lib/mydb.rb'
# MyPusherModule
require 'lib/mypusher.rb'
# MyGCalModule
require 'lib/mygcal.rb'
# MyAtModule
require 'lib/myat.rb'
