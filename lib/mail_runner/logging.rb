require 'time'
require 'logger'

module MailRunner
	module Logging 

		def self.initialize_logger(log_target = STDOUT)
	    oldlogger = defined?(@logger) ? @logger : nil
	    @logger = Logger.new(log_target, 'weekly')
	    @logger.level = Logger::INFO
	    @logger.formatter = proc do |severity, datetime, progname, msg|
		    date_format = datetime.strftime("%b %d %H:%M:%S ")    
		    "#{date_format} #{severity} (#{progname}): #{msg}\n"
			end


	    oldlogger.close if oldlogger && !$TESTING # don't want to close testing's STDOUT logging
	    @logger
	  end

    def self.logger
      defined?(@logger) ? @logger : initialize_logger
    end

    def self.logger=(log)
      @logger = (log ? log : Logger.new('/dev/null'))
    end 

    def self.add_log_file_section_header
	    @logger.info{"\n\nInitiate LogFile :: Session #{$redis.get("MR::sessions").to_i + 1} :: #{Time.now}\n########################################################"}
	  end
  end
end