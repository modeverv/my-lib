# -*- coding:utf-8 -*-

#
# Module of Machine
#
# this class has queue of jobs.controll jobs and run jobs
module MyMachine

  Version = "0.0.1"    

  attr_accessor :queue

  def initialize
    require 'thread'
    @queue = Queue.new
  end
  
  def setup
    setupjobs
    setupmachine
  end

  def go
    puts "You need write the go method!"
  end

  def retry(job)
    @queue.push job
  end

  private

  def setupjobs
    puts "You need write the setupjobs method!" 
  end
  
  def setupmachine
    puts "You need write the setupmachine method!"
  end

end


module MyMachineDojin
  include MyMachine

  def initialize(args={ })
    super()
    @args = args
    @args[:start] ||= 3000
    @args[:stop] ||= 3100
    @args[:concurrency] ||= 10
    @args[:savedir] ||= "#{ENV['HOME']}/Downloads/jpg"
    @endbooks = []
  end

  def bookend(booknum)
    @endbooks << booknum
  end

  def bookended?(booknum)
    @endbooks.index(booknum)
  end

  private

  def setupjobs
    (0..100).each do |p|
      (@args[:start]..@args[:stop]).each do |b|
        job = MyDojinJob.new(
          :server => '1patu.net',
          :book => b,
          :page => p,
          :machine => self,
          :debug  => @args[:debug] ||= false
          )
        @queue.push job
      end
    end
  end
end


class MyEventMachineDojin
  include MyMachineDojin

  def initialize(args={ })
    super args
    # queをEventMachineで再定義
    require 'rubygems'
    require 'eventmachine'
    @connection_count = 0
  end

  # EventMachine用の定義
  def go
    @a=1;@b=0;@c=0;@d=0;
    EM.run do
      EM.add_periodic_timer(0.00001) do
        @a-@b;@b-@c;@c-@d;@d-@a
        print 1>@a? "l".green: "l".yellow
        print 1>@b? "o".red: "o".white
        print 1>@c? "o".cyan: "o".green
        print 1>@d? "o".red: "o".green
        EM.stop if should_stop_machine?
        if !connection_exceed?
           @queue.pop.run unless @queue.empty?
        end
      end
    end
    p @endbooks
    @endbooks = []
    puts "End of fetch".green.bold
  end

  def connection_exceed?
    @args[:concurrency] <= @connection_count 
  end

  def connection_count!
    @connection_count += 1
    
  end

  def connection_end!
    @connection_count -= 1
  end

  private

  # EventMachine用に再定義
  def setupjobs
    (0..100).each do |p|
      (@args[:start]..@args[:stop]).each do |b|
        job = MyJobDojinEventMachine.new(
          :savedir => @args[:savedir],
          :server => '1patu.net',
          :book => b,
          :page => p,
          :machine => self,
          :debug  => @args[:debug] ||= false
          )
        @queue.push job
      end
    end
  end

  # 何もしない
  def setupmachine
  end

  # Machineは終了すべきか？
  def should_stop_machine?
    print " q:"+ @queue.size.to_s + "/c:" + @connection_count.to_s + " "
      return @queue.size == 0 && @connection_count == 0
  end

end

# 
# Class of Machine by EventMachine.
# this class controll jobs for Anisoku
# @example
#   machine = MyMachineAnisoku.new("YourVideoSaveDir")
#   machine.setup
#   machine.go
#
class MyMachineAnisoku
  include MyMachine

  Version = "0.0.1"    

  # directory of save video files default "#{ENV['HOME']}/Desktop/video"
  attr_accessor :savedir
  
  # set video save dir
  # @param [Hash] args
  # @option args [String] :savedir save dir
  #                        default "#{ENV['HOME']}/Desktop/video"
  def initialize(args={ })
    super()
    args[:savedir] ||= "#{ENV['HOME']}/Desktop/video"
    @savedir = args[:savedir]
    begin
      Dir::mkdir(@savedir, 0777)
    rescue => ex
      warn ex
    end
    require 'rubygems'
    require 'eventmachine'
    # @gaman controll eventmachine end
    @gaman = 0
    @checklist = {}
    @filelist = {}
    @dellist = []
    require 'pp'
    make_filelist
    make_dellist
    del_small_files
  end

  def make_filelist
    Dir.new(@savedir).each do |entry|
      if File.file?("#{@savedir}/#{entry}")
        header = make_header(entry) 
        filesize = File.size("#{@savedir}/#{entry}")
        @filelist[header] = [] unless chk_header(header)
        @filelist[header] << {:size => filesize,:name => "#{@savedir}/#{entry}" }
      end
    end
    pp @filelist
  end
  
  def chk_header(string) 
    @filelist[string]
  end    

  def make_header(string)
    header = string.scan(/^.*?\d{1,3}話/).first.gsub(' ','').gsub('　','')
    p header
    return header
  end

  def make_dellist
    @filelist.each do |k,v|
      p k
      max_size = v.map { |e| e[:size] }.max
      p max_size
      v.each do |vv|
        @dellist << vv[:name] if vv[:size] < max_size
      end
    end
    pp @dellist
  end

  def del_small_files
    @dellist.each do |e|
      p e
      File.delete("#{e}")
    end
  end

  def episode_exists?(key)
    if @checklist[key].nil?
#      puts "MACHINE NOE FIRST CHECK THIS EPISODE!!".red.bold
      @checklist[key] = "checked"
      return false
    else
      return true
    end
  end
  
  # machine go to run eventmachine
  def go
    EM.run do
      EM.add_periodic_timer(0.00001) do
#        print "loop".green
        if should_stop_machine?        
          finalize_files
          EM.stop
        end
        @queue.pop.run unless @queue.empty?
      end
    end
    puts "End of fetch".green.bold
  end


  # delete tiny fail files 
  def finalize_files
    command = "find #{@savedir} -size -1000k -type f -print0| xargs -0 rm -v "
    exec(command)
  end

  private

  # setup jobs
  def setupjobs
    ajob = MyJobAnisoku.new(
      :machine => self
      )
    @queue.push ajob
  end

  # should stop machine or not
  def should_stop_machine?
    @gaman += 1 if @queue.empty?
    print @gaman
    return @queue.empty? && @gaman > 1500
  end
end
