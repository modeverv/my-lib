#-*- coding:utf-8 -*-

# make String Colored
require 'rubygems'
require 'term/ansicolor'
class String
  include Term::ANSIColor
end

# Class For Log to /var/log/system.log
# @author modeverv@gmail.com
# @example
#   MyLogger.ln("message")
#   MyLogger.lw("message")
class MyLogger

  Version = "0.0.1"    

  # log notice
  # @param [String] message message for log
  def self.ln(message)
    self.before
    Syslog.log(Syslog::LOG_NOTICE, "%s", message)
    self.after
  end
  
  # log warning
  # @param [String] message message for log
  def self.lw(message)
    self.beventmachine_3000to3050_600_600_100.csvefore
    Syslog.log(Syslog::LOG_WARNING, "%s", message)
    self.after
  end
  
private
  # open syslog
  def self.before
    require 'syslog'
    include Syslog::Constants
    Syslog.open("ruby_syslog.rb")
  end
  # close syslog
  def self.after
    Syslog.close();
  end
  
end

# Job Class for Fetch Anisoku
# Function:
#   access "youtubeanisoku1.blog106.fc2.com" and crawl web site.
#   find a link to "say-move.org" and access "say-move.org".
#   finary find video link of Animetion,then fetch video file to your local.
#   save video directory is supplied by machine.
# Notice:
#   job is automatically generated on after another.
#   This Class Needs to be handle by Machine Class
# @example
#   # inside machine class     
#     job = MyJobAnisoku.new(
#      :machine => self
#     )
#     job.run
#   
class MyJobAnisoku

  Version = "0.0.2"    

  def initialize(args = { })
    require 'rubygems'
    require 'kconv'
    require 'mechanize'
    require 'net/http'
    @a = args
    @a[:url] ||= 'http://youtubeanisoku1.blog106.fc2.com/'
    @a[:url] = URI.parse @a[:url] unless @a[:url].class == URI::HTTP
    @agent = Mechanize.new
    @a[:status] ||= :new
    raise "job have no machine error"  unless @a[:machine]
  end

  # check kousin page
  def tokkakari
    print "Tokkakari".yellow
    @agent.get @a[:url]
    links_kousins = @agent.page.links_with(:text => /#{"更新状況".toutf8}/)
    targs = []
    links_kousins.each do |link|
      targs << link.uri
    end
    targs.each_with_index do |link,i|
      break if i > 6
      job = MyJobAnisoku.new(
        :url => link,
        :status => :second,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end
    
  end

  # check shoukai page
  def second
    print "Second".yellow
    @agent.get @a[:url]
    links_kousin =  @agent.page/"/html/body/table/tr[2]/td/table/tr/td[2]/div[4]/ul/li/a/@href"
    # links_kobetu 
    links_kobetu = []
    links_kousin.each do |link|
      links_kobetu << $1  if link.value =~ /(http:\/\/youtubeanisoku.*)/
    end

    # make job for each links_kobetu
    links_kobetu.each do |link|
      job = MyJobAnisoku.new(
        :url => link,
        :status => :kobetu,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end
  end

  #access say-move and make video job
  def kobetu
    print "Kobetu".yellow
    @agent.get @a[:url]
    _tt = @agent.page.title.gsub(' ★ You Tube アニ速 ★','')
    limit = 5
    urls = []
    # acume url
    nodeset_vs = @agent.page/"/html/body/table/tr[2]/td/table/tr/td[2]/div[4]/div[2]/a/@href"
    _dd = []

    nodeset_vs.each do |va|
      _dd << $1  if va.value =~ /(http:\/\/say-move\.org\/comeplay\.php.*)/
    end
    _dd.reverse!

    #hard coding for adjust fetch limit
    _dd.each_with_index do |url,i|
      break if i > limit
      urls << url
    end
    
    urls.each_with_index do |url,i|
      job = MyJobAnisoku.new(
        :url => url,
        :title => _tt,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end
  end

  #access say-move and make video job
  def third
    print "Third".yellow
    #sm has title and url

    sm = { :title => @a[:title],:url => @a[:url]}
    # debug fc2 video sm[:url] = "http://say-move.org/comeplay.php?comeid=217953"
    @agent.get(sm[:url])
    sm[:title] += @agent.page.title.gsub!('FC2 SayMove!','') 
    set =  @agent.page/"/html/body/div/div[2]/div[7]/div[2]/input/@value"
    if !set.empty?
      sm[:videourl] = set[0].value 
    else
      set =  @agent.page/"/html/body/div/div[2]/div[3]/object/param[5]/@value"
      fc2 = set[0].value.split('&')[1].split('=')[1]
      unless fc2.nil?
        job = MyJobAnisoku.new(
          :url => sm[:url],
          :fc2 => fc2,
          :title => sm[:title],
          :status => :fc2,
          :machine => @a[:machine]
          )
        @a[:machine].retry job
        return
      else
      end
    end
    
    job = MyJobAnisoku.new(
      :url => sm[:videourl],
      :title => sm[:title],
      :status => :video,
      :machine => @a[:machine]
      )
     @a[:machine].retry job
  end

  def fc2
    print "fc2".yellow
    require 'digest'
    # make md5 with magicword '_gGddgPfeaf_gzyr'
    url = "http://video.fc2.com/ginfo.php?mimi=#{Digest::MD5.hexdigest(@a[:fc2] + '_gGddgPfeaf_gzyr')}&v=#{@a[:fc2]}&upid=#{@a[:fc2]}&otag=1"
    url = `curl -# -L -R "#{url}"`
    url =  url.split('&')[0].split('=')[1] + '?' + url.split('&')[1]
    puts url.red.bold
    job = MyJobAnisoku.new(
      :url => url,
      :title => @a[:title],
      :status => :video,
      :machine => @a[:machine]
      )
     @a[:machine].retry job
  end

  #fetch video
  def video
    print "video".yellow
    # save video directory is supplied by machine.
    savedir = @a[:machine].savedir
    Dir.chdir savedir
    filename = "#{@a[:title]}.mp4"
    savepath = "#{savedir}/#{filename}"
    # check fetch candidate had been already saved?
    if File.exist?(savepath) && File.size(savepath) > 1024 * 1024 * 3
      puts "File Already Saved ".yellow.bold  + savepath
      return
    else
      puts "Fetching ".green.bold + savepath
      MyLogger.ln "Fetch Attempt Start ".green.bold  + savepath
    end
    
    # use curl command
    # no need UA...
    #    command = "curl -# -L -R -o '#{filename}' 'http://#{@a[:url].host}#{@a[:url].path}?#{@a[:url].query}' --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:9.0a1) Gecko/20110901 Firefox/9.0a1'"
    command = "curl -# -L -R -o '#{filename}' 'http://#{@a[:url].host}#{@a[:url].path}?#{@a[:url].query}' "

    p command
    system command
  end

  # run in thread
  def run
    t = Thread.new do
      case @a[:status]
      when :new then
        tokkakari
      when :second then
        second
      when :kobetu then
        kobetu
      when :third then
        third
      when :fc2 then
        fc2
      when :video then
        video
      end
    end
  end
  
end

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
    args[:savedir] ||= "#{ENV['HOME']}/Desktop/video2"
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


