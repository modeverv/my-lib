
# Googleカレンダーへのアクセスを提供する
#
# ~/config.ymlに
#  gmail:
#    address: YourMailAdress@gmail.com
#    pass: xxxxxxxxxx
#    feedurl: http://www.google.com/calendar/feeds/xxxxxxxx%40gmail.com/private/full
#
# 使い方など
# class ThisDo
#   include MyGCalModule
# して
# o = ThisDo.new
# o.gcal_read
# とかでok
module MyGCalModule
  attr_accessor :gmail,:gmailpass,:gcalfeedurl,:gcal_query
  
  def gcal_read
    service
    @gcal_events = @gcal.events
    return self
  end

  #GCalへ書きこむ
  def gcal_write(eventdata)
    service
    event = @gcal.create_event
    event.title = eventdata[:title]
    event.st = eventdata[:start]
    event.en = eventdata[:end]
    event.save!
    @gcal_event = event
    return self
  end

  # gcalのイベントをAtMduleが食べれる形に変換する
  # 共通のJOBクラスで包もうかしら?
  def gcal_parse_2_jobs
    @gcal_jobs = []
    q = @gcal_query ||= '[Gcal2PusherTail'
    @gcal_events.each do |event|
      begin
        kind,filename = event.title.split(']')
        if(kind == @gcal_query && filename != nil)
          @gcal_jobs << {:filename => filename,
            :start => event.st,
            :end => event.en,
            :object => event}
        end
      rescue =>ex
        p ex
        #握りつぶす
      end
    end
    return self
  end

  #fetchしたデータの取り込み済みマークを立てる
  def gcal_checkout(event)
    event.title = '[FETCHED]' + event.title
    event.save!
    return self
  end

  # GCalへのアクセス
  def service
    if @gcal_srv.nil?
      require 'gcalapi'
      @c = MyConfig.get['gmail']
      @gcal_srv = GoogleCalendar::Service.new(@c['address'],@c['pass'])
    end
    @gcal = GoogleCalendar::Calendar::new(@gcal_srv, @c['feedurl'])
  end
end
