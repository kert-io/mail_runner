require 'optparse'
module MailRunner
	class CLI
		

    def self.start(args)
      options = parse_options(args)
      initialize_logger(options)
      set_globals
      
      @bot = initialize_manager_bot(options)#run first to make sure it runs bot tests prior to daemonizing a process.
      daemonize unless options[:daemon].nil?
      @bot.run
    end


		def self.parse_options(argv)
      opts = {}
      @parser = OptionParser.new do |o|
        o.on '-m', '--mailbox MAILBOX', "Name of Mailbox to watch" do |arg|
          opts[:mailbox] = arg
        end

        o.on '-w', '--webhook URL', "Complete url of webhook to deliver mail to" do |arg|
          opts[:webhook] = arg
        end

        o.on '-a', '--archive', "Set to true id you want mail archived." do |arg|
          opts[:archive] = arg
        end

        o.on '-d', '--daemon', "Daemonize process. Be sure to add logfile path." do |arg|
          opts[:daemon] = arg
        end

        o.on '-L', '--logfile PATH', "Absolute path to log file." do |arg|
          opts[:logfile] = arg
        end

        o.on '-c', '--config PATH', "Path to YAML config file." do |arg|
          opts[:config] = arg
        end

        o.on '-v', '--verbose', "Logger runs in debug mode." do |arg|
          opts[:verbose] = arg
        end
      end
      @parser.parse!(argv)
      opts
    end

		def self.initialize_manager_bot(opts)
    	begin
			  bot = MailRunner.initialize_manager_bot
			  bot.verify_and_set(opts)
			rescue => e
			  puts e.message
			  exit 1
			end
      return bot
	  end

    def self.daemonize
      #eq_to Process.daemon
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir "/" 
      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null", "a" 
      STDERR.reopen "/dev/null", "a" 
    end

    def self.initialize_logger(options)
      begin
        MailRunner::Logging.initialize_logger(options[:logfile]) if options[:logfile]
        MailRunner::Logging.add_log_file_section_header if options[:logfile]
        MailRunner.logger.level = ::Logger::DEBUG if options[:verbose]
      rescue => e #primarily to alert invald log path in case of daemon
        puts e.message
        exit 1
      end
    end

    def self.set_globals
      MailRunner.set_globals
    end
	end
end

