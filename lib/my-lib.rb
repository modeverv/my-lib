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
    self.before
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
  def third
    #sm has title and url
    sm = { :title => @a[:title],:url => @a[:url]}
    @agent.get(sm[:url])
    set =  @agent.page/"/html/body/div/div[2]/div[7]/div[2]/input/@value"
    if set[0]
      sm[:videourl] = set[0].value 
    end

    job = MyJobAnisoku.new(
      :url => sm[:videourl],
      :title => sm[:title],
      :status => :video,
      :machine => @a[:machine]
      )
     @a[:machine].retry job
  end

  #access say-move and make video job
  def kobetu
    @agent.get @a[:url]
    nodeset = @agent.page/"/html/body/table/tr[2]/td/table/tr/td[2]/div[4]/div[2]"
        begin
    titles  = nodeset[0].inner_text.gsub('　','').gsub(' ','').
            gsub('「Daum」|','').
            gsub('【Yahoo!】','').
            gsub('veoh','').
            gsub('SM|','').
            gsub('|','').
            split("\r\n").
      select{|e| $1 if e=~/(第.*)/ }.
      map{|k| k =~ /(第(\d{1,2}).*)/; { :episode => $2, :title => $1} }
    titles.reverse!
    
    
    _tt = @agent.page.title.gsub(' ★ You Tube アニ速 ★','')

    #hard coding for adjust fetch limit
    title  = _tt + titles.shift[:title].to_s
    title2 = _tt + titles.shift[:title].to_s
    title3 = _tt + titles.shift[:title].to_s
    title4 = _tt + titles.shift[:title].to_s
    title5 = _tt + titles.shift[:title].to_s
          
    rescue => ex
      p ex
      return
    end
    nodeset_vs =  @agent.page/"/html/body/table/tr[2]/td/table/tr/td[2]/div[4]/div[2]/a/@href"
    _dd = []
    nodeset_vs.each do |va|
      _dd << $1  if va.value =~ /(http:\/\/say-move\.org\/comeplay\.php.*)/
    end
    _dd.reverse!

    #hard coding for adjust fetch limit
    url  = _dd.shift
    url2 = _dd.shift
    url3 = _dd.shift
    url4 = _dd.shift
    url5 = _dd.shift

    #hard coding for adjust fetch limit
    unless url.nil?
      job = MyJobAnisoku.new(
        :url => url,
        :title => title,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end
    
    unless url2.nil?
      job = MyJobAnisoku.new(
        :url => url2,
        :title => title2,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end

    unless url3.nil?
      job = MyJobAnisoku.new(
        :url => url3,
        :title => title3,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end

    unless url4.nil?
      job = MyJobAnisoku.new(
        :url => url4,
        :title => title4,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end

    unless url5.nil?
      job = MyJobAnisoku.new(
        :url => url5,
        :title => title5,
        :status => :third,
        :machine => @a[:machine]
        )
      @a[:machine].retry job
    end
    
  end

  #fetch video
  def video
    # save video directory is supplied by machine.
    savedir = @a[:machine].savedir
    Dir.chdir savedir
    filename = "#{@a[:title]}.mp4"
    savepath = "#{savedir}/#{filename}"

    puts "Fetching ".green.bold + savepath

    if File.exist?(savepath) && File.size(savepath) > 1024 * 1024 * 3
      puts "File Already Saved ".yellow.bold  + savepath
      return
    else
      MyLogger.ln "Fetch Attempt Start ".green.bold  + savepath
    end
    # use curl command
    command = "curl -# -L -R -o '#{filename}' '#{@a[:url].host}#{@a[:url].path}'"
    system command
=begin
consume too much memory!!!!
    begin
    @http = EventMachine::Protocols::HttpClient.request(
      :host => @a[:url].host,
      :port => @a[:url].port,
      :request => @a[:url].path
    )
    rescue => ex
      p ex
      return
    end
    
    @http.callback {|response|
      if response[:status] == 200
        puts "# 200".green
        open(savepath,"wb") do |io|
          io.write response[:content]
        end
        puts "saved:".green.bold + "/Users/seijiro/Desktop/#{@a[:title]}.mp4"
      elsif response[:status] == 302
        puts "302".red.bold
        location = ""
        response[:headers].each do |elem|
          p elem
          location = $1 if elem =~ /Location:\s(.*)/
        end
        job = MyJobAnisoku.new(
          :url => location,
          :title => @a[:title],
          :status => :video,
          :machine => @a[:machine]
          )
        @a[:machine].retry job
      else 
        puts response[:status].to_s.red.bold
        puts response[:headers].to_s.red.bold
#        raise "HTTP Status Error"
      end
    }
=end
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
      when :video then
        video
      end
    end
  end
  
end

# Module of Machine
#   this class has queue of jobs
#   controll jobs and run jobs
module MyMachine
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
# Class of Machine by EventMachine
#   this class controll jobs for Anisoku
# @example
#   machine = MyMachineAnisoku.new("YourVideoSaveDir")
#   machine.setup
#   machine.go
#
class MyMachineAnisoku
  include MyMachine
  attr_accessor :savedir

  # set video save dir
  # @param [Hash] args
  # @option args [String] :savedir save dir
  #                        default "${ENV['HOME']}/Desktop/video"
  def initialize(args={ })
    super()
    args[:savedir] ||= "${ENV['HOME']}/Desktop/video"
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

  # macine go!!
  def go
    EM.run do
      EM.add_periodic_timer(0.00001) do
#        print "loop".green
        EM.stop if should_stop_machine?
        @queue.pop.run unless @queue.empty?
      end
    end
    puts "End of fetch".green.bold
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
    return @queue.empty? && @gaman > 500
  end
end
