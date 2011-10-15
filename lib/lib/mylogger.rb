
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
