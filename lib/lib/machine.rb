# -*- coding:utf-8 -*-

#
# Module of Machine
#
# this class has queue of jobs.controll jobs and run jobs
module MyMachine

  def initialize(args={})
    require 'thread'
    require 'pp'
    @queue = Queue.new
    @debug = args[:debug]||= false
  end
  
  def setup
    setupjobs
    setupmachine
  end

  def go
    raise "You need write the go method!"
  end

  def retry(job)
    @queue.push job
  end

  private

  def setupjobs
    puts "iF need, write the setupjobs method!" 
  end
  
  def setupmachine
    puts "if need, write the setupmachine method!"
  end

end

class MyEventMachineDojin
  include MyMachine

  def initialize(args={ })
    super(args)
    @args = args
    @args[:start] ||= 3000
    @args[:stop] ||= 3100
    @args[:concurrency] ||= 10
    @args[:savedir] ||= "#{ENV['HOME']}/Downloads/jpg"
    @endbooks = []
    require 'rubygems'
    require 'eventmachine'
    @connection_count = 0
    require 'thread'
    @connection_que = Queue.new
    @list = []
    @gaman = 0
  end

  # EventMachine用の定義
  def go
    EM.run do
      EM.add_periodic_timer(0.00001) do
        print "."
        EM.stop if should_stop_machine?
        if !connection_exceed?
          unless @queue.empty?
            job = @queue.pop
            job.run if job
          end
        end
      end
    end
    p @endbooks.uniq!.sort if @debug
    puts "End of fetch".green.bold
  end

  def connection_exceed?
    @args[:concurrency] <= @connection_que.size
  end

  def connection_count!
    @connection_que.push(:t)
  end

  def connection_end!
    @connection_que.pop
  end
  
  def savecontent(path)
    @list <<  path
  end

  def write
    open("#{@args[:savedir]}/emit.txt" ,"w") do |io|
      io.write('["')
      io.write(@list.sort.join('","'))
      io.write('"]')
    end
  end
  
  private

  def setupjobs
    (0..100).each do |p|
      (@args[:start]..@args[:stop]).each do |b|
        job = MyJobDojinEventMachine.new(
          :savedir => @args[:savedir],
          :server => '1patu.net',
          :book => b,
          :page => p,
          :machine => self,
          :debug  => @debug,
          )
        @queue.push job
      end
    end
  end

  # Machineは終了すべきか？
  def should_stop_machine?
    @gaman += 1  if @queue.size < 10
    if @gaman > 200
      write if @queue.size == 0
      return true
    end
  end

end

class MyMachineAnime44
  include MyMachine

  attr_reader :savedir
  
  def initialize(args={ })
    require 'eventmachine'
    super(args)
    args[:savedir] ||= "#{ENV['HOME']}/Desktop/video"
    @savedir = args[:savedir]
    begin
      Dir::mkdir(@savedir, 0777)
    rescue => ex
      warn ex
    end
    @args = args
    @args[:recursive] ||= 2
    @gaman = 0;
  end

  # machine go to run eventmachine
  def go
    EM.run do
      EM.add_periodic_timer(0.00001) do
#        print "loop".green
        if should_stop_machine?
          EM.stop
        end
        @queue.pop.run unless @queue.empty?
      end
    end
    puts "End of fetch".green.bold
  end
  
  # setup jobs
  def setupjobs
      ajob = MyJobAnime44
        .new(
             :machine => self,
             :recursive => @args[:recursive],
             :debug => @debug,
             )
    @queue.push ajob
  end
  
  # Machineは終了すべきか？
  def should_stop_machine?
    @gaman += 1  if @queue.size < 3
    if @gaman > 1000
      return true
    end
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

  # directory of save video files default "#{ENV['HOME']}/Desktop/video"
  attr_accessor :savedir
  
  # set video save dir
  # @param [Hash] args
  # @option args [String] :savedir save dir
  #                        default "#{ENV['HOME']}/Desktop/video"
  def initialize(args={ })
    super(args)
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

    @args = args
    @args[:limit] ||= 7
    @args[:recent] ||= 7
    @args[:mode]   ||= :anisoku
    make_filelist
    make_dellist
  end

  def make_filelist
    Dir.new(@savedir).each do |entry|
      if File.file?("#{@savedir}/#{entry}")
        header = make_header(entry)
        if header
          filesize = File.size("#{@savedir}/#{entry}")
          @filelist[header] = [] unless chk_header(header)
          @filelist[header] << {
            :size => filesize,
            :name => "#{@savedir}/#{entry}",
          }
        end
      end
    end
    pp @filelist if @debug
  end
  
  def chk_header(string) 
    @filelist[string]
  end    

  def make_header(string)
    if string.scan(/^.*?\d{1,3}話/).first
      header = string.scan(/^.*?\d{1,3}話/).first.gsub(' ','').gsub('　','')
    end
    p header if @debug
    return header
  end

  def make_dellist
    @filelist.each do |k,v|
      p k if @debug
      max_size = v.map { |e| e[:size] }.max
      p max_size if @debug
      v.each do |vv|
        if vv[:size] < max_size || vv[:size] < 1024 * 1024 * 2
          @dellist << vv[:name]
        end
      end
    end
    pp @dellist if @debug
  end

  def del_small_files
    @dellist.each do |e|
      p e if @debug
      File.delete("#{e}")
    end
  end

  def episode_exists?(key)
    if @checklist[key].nil?
      puts "MACHINE NOE FIRST CHECK THIS EPISODE!!".red.bold if @debug
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
    del_small_files
    command = "find #{@savedir} -size -1000k -type f -print0| xargs -0 rm -v "
    exec command
    command = "find /Users/seijiro/Desktop/video -type f > ~/Desktop/video.m3u && open ~/Desktop/video.m3u "
    exec command
  end

  private

  # setup jobs
  def setupjobs
    ajob = MyJobAnisoku
      .new(
           :machine => self,
           :limit => @args[:limit],
           :recent => @args[:recent],
           :debug => @debug,
           )
    if @args[:mode] == :anime44
      ajob = MyJobAnime44
        .new(
             :machine => self,
             :limit => @args[:limit],
             :recent => @args[:recent],
             :debug => @debug,
             )
    end
    @queue.push ajob
  end

  # should stop machine or not
  def should_stop_machine?
    @gaman += 1 if @queue.empty?
    print @gaman if @debug
    return @queue.empty? && @gaman > 4000
  end
end
