require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "MyLib" do
  it "fails" do
#    fail "hey buddy, you should probably rename this file and start specing for real"
  end

  it "success" do
    ####################################################
    machine = MyMachineAnisoku.new
    machine.setup
#    machine.go
  end

  it "success get syslog" do
    MyLogger.ln "notice"
    MyLogger.lw "warn"
  end
end
