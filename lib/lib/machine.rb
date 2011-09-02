
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

