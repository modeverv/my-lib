#-*- coding:utf-8 -*-
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


class MyJobDojin

  def initialize(args = { })
    require 'net/http'
    @args = args

    #sample http://1patu.net/data/20591/preview/000.jpg
    @args[:path]   = "/data/#{@args[:book].to_s}/preview/" +
                     sprintf("%0#{3}d", @args[:page]) + ".jpg"
    @args[:cookie] ||= { 'Cookie' => '1patu_view=1'}
    @args[:status] = :new
    @args[:try]    = 0

    @args[:savedir] ||= "/Users/seijiro/Downloads/jpg"
    @args[:savebookdir] = "#{@args[:savedir].to_s}/#{@args[:book].to_s}"
    checkdir
    @args[:savepath] = "#{@args[:savebookdir]}/" +
                       sprintf("%0#{3}d", @args[:page]) + ".jpg"
    @machine = @args[:machine]

    #debug
    @args[:debug]  ||= false
    @args[:savepath] = '/dev/null' if @args[:debug]
  end

  def run
    do_connect
  end

  private
  
  def do_connect
    puts "Do Connect".green
    return if @machine.bookended?(@args[:book])
    return if file_already_saved?
    
    Net::HTTP.start(@args[:server]) do |http|
      response = http.get(@args[:path],@args[:cookie])

      case response
      when Net::HTTPSuccess     then
        save_content(response.body)
      when Net::HTTPClientError     then
        @machine.bookend(@args[:book])
      when Net::HTTPServerError     then
        puts "Net::HTTPSereverError".red
        Thread.sleep 2
        @args[:try] += 1
        if @args[:try] < 6
          @machine.retry(self)
        else
        end
      when Net::HTTPRedirection then
        puts "Net::HTTPRedirection"
      else
        puts (response.error!).red.bold
      end        
    end
  end
  
  def save_content(content)
    open(@args[:savepath],"wb") do |io|
      io.write(content)
    end
    print "fetched:".green.bold + @args[:path]
  end

  # ダウンロード保存先を作る
  def checkdir
    begin
      Dir::mkdir(@args[:savebookdir], 0777)
    rescue => ex
#      warn ex
    end
  end

  def file_already_saved?
    File.exist?(@args[:savepath]) && FileTest.size(@args[:savepath]) > 0
  end
  
end


# for EventMachine
class MyJobDojinEventMachine < MyJobDojin
  
  private
  
  def do_connect
    return if @machine.bookended?(@args[:book])
    return if file_already_saved?

    if @machine.connection_exceed? #コネクション限界を超えていないか？
      @machine.retry(self)
      return
    end

    @machine.connection_count!

    @http = EventMachine::Protocols::HttpClient.request(
      :host => @args[:server],
      :port => @args[:port],
      :request => @args[:path],
      :cookie => @args[:cookie]['Cookie']
    )

    @http.callback {|response|
      @machine.connection_end!
      if response[:status] == 200
        # 200 はレスポンスの中身を保存する
        save_content(response[:content])
      elsif response[:status] == 503 ||
            response[:status] == 500 ||
            response[:status] == 403
        # 503/500/403はリトライする
        @args[:try] += 1
        @machine.retry(self) if @args[:try] < 6
      elsif response[:status] == 404
        # 404は終了する
        @machine.bookend(@args[:book])
      else 
        puts response[:status].to_s.red.bold
        puts response[:headers].to_s.red.bold
      end
    }
  end
end

