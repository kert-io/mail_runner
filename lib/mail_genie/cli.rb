require 'optparse'
module MailGenie
	class CLI
		

		def self.start(args)
			command = args.shift.strip 
			options = parse_options(args)
	    initiate_cmd(command, options)
		end


		def self.parse_options(argv)
      opts = {}
      @parser = OptionParser.new do |o|
      	puts argv.inspect
        o.on '-m', '--mailbox MAILBOX', "Name of Mailbox ot watch" do |arg|
          opts[:mailbox] = arg
        end

        o.on '-w', '--webhook URL', "Complete url of webhook to deliver mail to" do |arg|
          opts[:webhook] = arg
        end

        o.on '-a', '--archive', "set to true id you want mail archived" do |arg|
          opts[:webhook] = arg
        end

        o.on '-d', '--daemon', "Daemonize process" do |arg|
          opts[:daemon] = arg
        end
      end
      @parser.parse!(argv)
      opts
    end

		def self.initiate_cmd(cmd, opts)
	    case cmd
	    when 'start' #'mgb' #mailGetterBot
	    	begin
				  bot = MailGenie::MailGetterBot.new
				  bot.initiate(opts)
				rescue => e
				  puts e.message
				  exit 1
				end
			when'-fake'
				puts "Kidder!"
			when '-help', '-h'
				puts "show help"
			else
				puts "Invalid arguments. Check README.md for proper format." 
				exit
	    end
	  end
	  
	end
end

