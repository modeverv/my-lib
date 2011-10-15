# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "MyLib" do
  it "fails" do
#        fail "hey buddy, you should probably rename this file and start specing for real"
  end

  it "success" do
    ####################################################
    machine = MyMachineAnisoku.new(:savepath => "/Users/seijiro/Desktop/video")
    machine.setup
    #    machine.go
  end

  it "success get syslog" do
    MyLogger.ln "notice"
    MyLogger.lw "warn"
  end
end


describe "MyLogger" do

  it "log should success" do
    MyLogger.ln("nihogno")
    MyLogger.lw("nihogno")
  end
  
end

describe "MyConfig" do
  it "get should be success" do
    MyConfig.get
  end

  it "set config file failue" do
    proc { 
      MyConfig.dispose
      MyConfig.set "aaaaaaaaaaa.yml"
      p MyConfig.get
    }.should raise_error
  end
end


describe "MyJobAnisoku" do

  before(:each) do
    @machine = MyMachineAnisoku.new
    @machine.setup
    @job = MyJobAnisoku.new(:machine => @machine)
  end
  
  it "check new" do
    #    fail
    a = @job.a
    fail unless a[:url] 
    fail unless a[:status] 
    fail unless a[:recent] 
    fail unless a[:limit] 
    fail unless a[:fc2magick] 
  end

  it "tokkakariを実行するとjobが増える" do
    jobqsize = @machine.instance_eval("@queue.size")
    p jobqsize
    @machine.instance_eval("@queue.pop.tokkakari")
    jobqsize2 = @machine.instance_eval("@queue.size")
    p jobqsize2
    fail unless jobqsize < jobqsize2
  end

  it "tokkakariを実行するとjobが増える" do
    jobqsize = @machine.instance_eval("@queue.size")
    p jobqsize
    @machine.instance_eval("@queue.pop.tokkakari")
    jobqsize2 = @machine.instance_eval("@queue.size")
    p jobqsize2
    fail unless jobqsize < jobqsize2
  end


end
