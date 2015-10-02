require 'mail'
require 'json'
require 'base64'
require 'rest-client'
require 'redis'

module MailRunner

	class MailGetterBot 

		# loads all BotHelper Modules & then extends class.
		Dir[File.dirname(__FILE__) + '/mail_getter_bot/*.rb'].each {|file| require file }
		
		extend BotHelpers

		#used for testing
		attr_accessor :mailbox
    attr_accessor :webhook
    attr_accessor :archive


		def initialize
      @mailbox = nil
      @webhook = nil
      @archive = false
    end

    def initiate(opts)
  		parse_options(opts)
		  test_options
		  run
		end

    def parse_options(opts)
			BotHelpers::Tests.all_args_included?(opts)
			
    	@mailbox = "/var/mail/#{opts[:mailbox]}"
    	@webhook = opts[:webhook]
    	@archive ||= opts[:archive] == "true" ? true : false 
    end


    def test_options
    	BotHelpers::Tests.test_mailbox(self.mailbox)
    	BotHelpers::Tests.test_webhook(self.webhook)
    end


		def run
			BotHelpers::Helpers.print_monitoring_started_msg(self)

			while true 

				raw_mail = BotHelpers::Runner.get_contents_from_mailbox(self.mailbox)	
				unless raw_mail.nil?

					raw_mail.each do |raw_msg|		

						mail = Mail.read_from_string(raw_msg)
						json_packet = BotHelpers::Helpers.convert_raw_mail_to_json(mail)

						begin
							BotHelpers::Runner.post_to_hook(self.webhook, json_packet)
						rescue Exception => msg 
							puts msg.inspect
							queued = BotHelpers::Runner.add_to_mail_queue(webhook, json_packet)
						end

						if self.archive == true && queued.nil?
							puts "we will archive email.\n"
						end
						
					end

				end

				sleep 5
			end
		end
		
	end
end