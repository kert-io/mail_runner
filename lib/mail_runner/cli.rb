require 'optparse'
module MailRunner
	class CLI
		

		def self.start(args)
			options = parse_options(args)
	    run(options)
		end


		def self.parse_options(argv)
      opts = {}
      @parser = OptionParser.new do |o|
        o.on '-m', '--mailbox MAILBOX', "Name of Mailbox ot watch" do |arg|
          opts[:mailbox] = arg
        end

        o.on '-w', '--webhook URL', "Complete url of webhook to deliver mail to" do |arg|
          opts[:webhook] = arg
        end

        o.on '-a', '--archive', "Set to true id you want mail archived." do |arg|
          opts[:webhook] = arg
        end

        o.on '-d', '--daemon', "Daemonize process" do |arg|
          opts[:daemon] = arg
        end

        o.on '-c', '--config', "Path to YAML config file." do |arg|
          opts[:daemon] = arg
        end
      end
      @parser.parse!(argv)
      opts
    end

		def self.run(opts)
    	begin
			  bot = MailRunner::MailGetterBot.new
			  bot.initiate(opts)
			rescue => e
			  puts e.message
			  exit 1
			end
	  end

	end
end

