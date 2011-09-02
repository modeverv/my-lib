
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



