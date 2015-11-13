require 'mail'
require 'json'
require 'base64'
require 'rest-client'
require 'redis'
require 'fog'

module MailRunner

	class ManagerBot 

    # loads all BotHelper Modules & then extends class.
    Dir[File.dirname(__FILE__) + '/bot_helpers/*.rb'].each {|file| require file }

    extend BotHelpers

    #used for testing
    attr_accessor :mailbox
    attr_accessor :webhook
    attr_accessor :archive
    attr_accessor :webhook_status

    
   
    def initialize
      @mailbox = nil
      @webhook = nil
      @archive = nil
      @webhook_status = nil
    end


    def verify_and_set(opts)
      parse_options(opts)
      test_options       
    end

    def parse_options(opts)
    	BotHelpers::Tests.all_args_included?(opts)
    	
    	@mailbox = "/var/mail/#{opts[:mailbox]}"
    	@webhook = opts[:webhook]
    	@archive = opts[:archive].nil? ? nil : opts[:archive] 
    end

    def update_webhook_status(status)
    	@webhook_status = status
    end

    def test_options
    	BotHelpers::Tests.test_mailbox(self.mailbox)
      BotHelpers::Tests.test_webhook(self.webhook)
      BotHelpers::Tests.test_archive(self.archive) unless self.archive.nil?
    end

    def run
    	BotHelpers::Helpers.print_monitoring_started_msg(self)
    	$mad_statter.incr_stat("runner launched")
    	while true 

    		delegate_inbound_processing
    		
    		if webhook_status == "down"
    			BotHelpers::Tests.soft_test_webhook(self.webhook)
    		elsif delayed_queue?
    			delegate_delayed_queue_processing
    		end

        if archive_stack?
          delegate_archive_stack_processing
        end

    		sleep 5
    	end
    end

#### Delegation Methods ####

    def inbound_manager
    	MailRunner::InboundManagerBot
    end

    def delegate_inbound_processing
    	begin
    		inbound_manager.process_inbound(mailbox, webhook, archive)
    	rescue Exception => msg 
    		puts msg.inspect
    	end
    end


    def queue_manager
    	MailRunner::QueueManagerBot
    end

    def delayed_queue?
    	queue_manager.queue_length > 0
    end

    def delegate_delayed_queue_processing
    	begin
    		queue_manager.process_queue
    	rescue Exception => msg 
    		puts msg.inspect
    	end
    end

    def archivist
      MailRunner::ArchivistBot
    end

    def archive_stack?
      archivist.stack_height > 0
    end

    def delegate_archive_stack_processing
      begin
        archivist.archive_stack
      rescue Exception => msg 
        puts msg.inspect
      end
    end
		
	end
end