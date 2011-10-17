#-*- coding:utf-8 -*-

class MyJobAnime44
  def initialize(args={})
    require 'kconv'
    require 'mechanize'
    require 'net/http'
    @a = args
    @debug = args[:debug] ||= false
    @a[:url] ||= 'http://www.anime44.com/'
    @a[:status] ||= :top_page
    return if @a[:url].nil?
    @agent = Mechanize.new
    @a[:recursive] ||= 4
  end
  #   
  def top_page
    print :top_page if @debug
    @agent.get @a[:url]
    #    p @agent.page
    @agent.page.search('table')[1].css('td li')
    targs =  @agent.page.search('table')[1].css('td li').select {|ne| ne.text =~ /\(Raw\)/ }
    a_s = []
    targs.each {|ne| a_s << ne.css('a').map{|e|e[:href]}[0]}
    a_s.each do |link|
      job = MyJobAnime44.new(@a.merge({
                                        :url => link,
                                        :status => :anime44_first
                                      }))
      @a[:machine].retry job
    end
  end

  def anime44_first
    print :anime44_first if @debug
    puts @a[:url] if @debug
    begin
      @agent.get @a[:url]
    rescue => ex
      p ex if @debug
      p @a[:url] if @debug
      return 
    end
    @title = @agent.page.title

    flg = false
    
    daily_embeds_links = @agent.page.search('embed[@src^="http://www.daily"]').map {|ne| ne[:src] }
    
    unless daily_embeds_links[0].nil?
      uri = daily_src2hqurl(daily_embeds_links[0])
      if uri[:status] == :ok
        flg = true
        job = MyJobAnime44.new(
                               @a.merge({
                                          :url => uri[:url],
                                          :title => @title,
                                          :status => :anime44_fetch}))
        @a[:machine].retry job
      end
    end

    unless flg == true
      begin
        @agent.get @a[:url]
      rescue => ex
        p ex if @debug
        p @a[:url] if @debug
        return 
      end
      
      videozer_embeds_links = @agent.page.search('embed[@src^="http://www.videozer"]').map {|ne| ne[:src] }
      unless videozer_embeds_links[0].nil?
        flg = true
        url1 = videozer_embeds_links[0].gsub('http://www.videozer.com/embed/','http://video195.videozer.com/video?v=')
        url = "#{url1}&r=1&t=#{Time.new.to_i.to_s}&u=&start=0"
        job = MyJobAnime44.new(
                               @a.merge({
                                          :url => url,
                                          :title => @title,
                                          :status => :anime44_fetch}))
        @a[:machine].retry job
      end
    end
    
    
    begin
      if @a[:recursive] > 0
        alignleft = @agent.page.search('div.alignleft a')[0]['href']
        job = MyJobAnime44.new(
                               @a.merge({
                                          :url => alignleft,
                                          :recursive => @a[:recursive] -1 ,
                                          :status => :anime44_first}))
        @a[:machine].retry job
      else
        p "recursive stop" if @debug
      end
    rescue => ex
    end
    
    begin
      if @a[:recursive] > 0
        alignright = @agent.page.search('div.alignright a')[0]['href']
        job = MyJobAnime44.new(
                               @a.merge({
                                          :url => alignright,
                                          :recursive => @a[:recursive] - 1,
                                          
                                          :status => :anime44_first}))
        @a[:machine].retry job
      else
        p "recursive stop" if @debug
      end
    rescue => ex
    end
  end

  def anime44_fetch
    print "video".yellow

    savedir = @a[:machine].savedir
    Dir.chdir savedir

    filename = "#{@a[:title].gsub(' ','').gsub('　','')}.mp4"
    savepath = "#{savedir}/#{filename}"

    if File.exist?(savepath) && File.size(savepath) > 1024 * 1024 * 3
      puts "File Already Saved ".yellow.bold  + savepath
      return
    else
      puts "Fetching ".green.bold + savepath
      MyLogger.ln "Fetch Attempt Start ".green.bold  + savepath
    end
    # use curl command
    # no need UA...
    command = "curl -# -L -R -o '#{filename}' '#{@a[:url]}' >/dev/null 2>&1 &"
    puts command 
    system command unless @debug
  end

  def daily_src2hqurl(url)
    require 'json'
    begin
      js= JSON.parse(@agent.get(url.gsub('swf','sequence/full')).body)
      uri = js[0]['layerList'][0]['sequenceList'][1]['layerList'][2]['param']['videoPluginParameters']['hqURL']
    rescue =>ex
      return {:status => :error}
    end
    {:status => :ok,:url => uri}
  end
  
  def run
    send @a[:status]
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
    @debug = args[:debug] ||= false
    @a[:url] ||= 'http://youtubeanisoku1.blog106.fc2.com/'
    @a[:url] = URI.parse @a[:url] unless @a[:url].class == URI::HTTP
    @agent = Mechanize.new
    @a[:status] ||= :new
    @a[:recent] ||= 7
    @a[:limit] ||= 4
    # make md5 with magicword '_gGddgPfeaf_gzyr'
    @FC2magick = @a[:fc2magick] ||='_gGddgPfeaf_gzyr'  #updated FC2 2011.7
    raise "job have no machine error"  unless @a[:machine]
    p @a if @debug && @a[:status] == :new
  end

  # check kousin page
  def tokkakari
    print "Tokkakari".yellow
    @agent.get @a[:url]
    links_kousins = @agent.page.links_with(:text => /#{"更新状況"}/)
    links_kousins2 = @agent.page.links_with(:href => /blog\-entry/)
    targs = []
    targs2 = []

    links_kousins.each do |link|
      targs << link.uri
    end
    
    links_kousins2.each do |link|
      targs2 << link.uri
    end

    targs.each_with_index do |link,i|
      break if i >= @a[:recent]
      p link if @debug
      job = MyJobAnisoku
        .new(
             @a.merge({
                        :url => link,
                        :status => :second,
                      }) )
      @a[:machine].retry job
    end
    
    targs2.each_with_index do |link,i|
      p link if @debug
      job = MyJobAnisoku
        .new(
             @a.merge({
                        :url => link,
                        :status => :kobetu,
                      }) )
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
      p link if @debug
      job = MyJobAnisoku.new(
                             @a.merge({
                                        :url => link,
                                        :status => :kobetu
                                      } ))
      @a[:machine].retry job
    end
  end

  #access say-move and make video job
  def kobetu
    print "Kobetu".yellow
    @agent.get @a[:url]
    title = @agent.page.title.gsub(' ★ You Tube アニ速 ★','')
    # acume url
    htmlA = @agent.page/"/html/body/table/tr[2]/td/table/tr/td[2]/div[4]/div[@class='kijisub']"
    require 'pp'
    targsHTMLs = htmlA.inner_html.toutf8.split(/ランキング/)[0].split(/\n第/).reverse!
    #http://posterous.com/getfile/files.posterous.com/temp-2011-08-21/eolunzlwwwFopCnhszaBwJlFEJEnHcloqkoyaFuhdezmdgipcyyiyzdpqcpG/cro08nyoutube.doc
    require 'digest' 
    targsHTMLs.each_with_index do |html,i|
      break if i >= @a[:limit]
      key = title + html.to_s
      unless @a[:machine].episode_exists?( Digest::MD5.hexdigest(key)  )
        #        puts "NOW 2 PROCEED FETCH".green.bold + html[0..20].yellow.bold
        indi = Nokogiri::HTML.fragment(html).css("a")
        indi.each do |va|
          p va[:href] if @debug
          if va[:href] =~ /(http:\/\/say-move\.org\/comeplay\.php.*)/
            job = MyJobAnisoku.new(
                                   @a.merge({
                                              :url => $1,
                                              :title => title + '第' + html.split('<').first.gsub(' ','').gsub('　',''),
                                              :status => :third}))
            @a[:machine].retry job
          end
        end
      else
        puts "ALREADY REGISTED CANCELL FETCH".cyan.bold + html[0..20].yellow.bold if @debug
      end
      key = nil
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
        p sm[:url] if @debug
        job = MyJobAnisoku.new(
                               @a.merge({
                                          :url => sm[:url],
                                          :fc2 => fc2,
                                          :title => sm[:title],
                                          :status => :fc2
                                        }))
        @a[:machine].retry job
        return
      else
      end
    end
    
    job = MyJobAnisoku.new(
                           @a.merge({
                                      :url => sm[:videourl],
                                      :title => sm[:title],
                                      :status => :video
                                    }))
    @a[:machine].retry job
  end

  def fc2
    print "fc2".yellow
    require 'digest'
    url = "http://video.fc2.com/ginfo.php?mimi=#{Digest::MD5.hexdigest(@a[:fc2] + @FC2magick)}&v=#{@a[:fc2]}&upid=#{@a[:fc2]}&otag=1"
    url = `curl -# -L -R "#{url} "`
    url =  url.split('&')[0].split('=')[1] + '?' + url.split('&')[1]
    puts url.red.bold
    job = MyJobAnisoku.new(
                           @a.merge({
                                      :url => url,
                                      :status => :video
                                    }))
    @a[:machine].retry job
  end

  #fetch video
  def video
    print "video".yellow
    # save video directory is supplied by machine.
    savedir = @a[:machine].savedir
    Dir.chdir savedir
    filename = "#{@a[:title].gsub(' ','').gsub('　','')}.mp4"
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
    uri = "http://#{@a[:url].host}#{@a[:url].path}"
    uri += "?#{@a[:url].query}" if @a[:url].query
    command = "curl -# -L -R -o '#{filename}' '#{uri}' >/dev/null 2>&1"
    #    command += "&& growlnotify -t '#{filename}' -m '#{uri}' "

    puts command if @debug
    system command unless @debug
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

  attr_accessor :args
  
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
    @args[:savepath] = '/dev/null' if @args[:dryrun]
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
    @machine.savecontent(@args[:savepath])
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
    return if file_already_saved?

    #      if @machine.connection_exceed? #コネクション限界を超えていないか？
    #        @machine.retry(self)
    #        print "E".red.bold
    #        return
    #      end

    @http = EventMachine::Protocols::HttpClient.
      request(
              :host => @args[:server],
              :port => @args[:port],
              :request => @args[:path],
              :cookie => @args[:cookie]['Cookie']
              )
    @machine.connection_count!
    @http.errback{
      begin
      ensure
        @machine.connection_end!
      end
    }

    @http.callback {|response|
      begin
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
        else 
          puts response[:status].to_s.red.bold
          puts response[:headers].to_s.red.bold
        end
      ensure
        @machine.connection_end!
      end
    }
  end
end

