module BotHelpers
	module Tests  #series of initial command validation tests on launch. 
  	
    def self.all_args_included?(args)
    	if args[:mailbox].nil? or args[:webhook].nil?
    		raise ArgumentError, 'You must include mailbox & webhook minimum. Archive argument is optional. Add -h to see help.' 
  		end
  	end
  	
  	def self.test_mailbox	(path)
    	unless File.file?(path)
    		raise ArgumentError, 'ERROR: Mailbox not valid' 
    	end
    end

    def self.test_webhook(url) 
    	begin
    		response = RestClient.head url
        MailRunner.manager_bot.update_webhook_status("live")
    	rescue  
    		raise ArgumentError, "ERROR: \nMake sure the server is running and the webhook exists.\nNOTE:  Server must respond to http HEAD method.\nSee README.md for proper setup.\n"
    	end
    	unless response.code == 200
    		raise ArgumentError, "ERROR: Invalid Webhook. NOTE, Must respond to http HEAD method."
    	end
    end

    def self.soft_test_webhook(url) 
      begin
        response = RestClient.head url
        MailRunner.manager_bot.update_webhook_status("live")
        $logger.info("ManagerBot") {"webhook status: live"}
      rescue 
      end
    end

    def self.test_archive(a_set)
      if a_set[:destination] == 'local'
        test_local_archive(a_set)
      elsif a_set[:destination] == 'cloud'
        test_cloud_archive_connection(a_set)
      else
        raise ArgumentError, "ERROR: Archive destination setting invalid."
      end
    end

    def self.test_local_archive(a_set)
      unless File.directory?(a_set[:local_archive])
        raise ArgumentError, "ERROR: Invalid local archive path."
      end
    end

    def self.test_cloud_archive_connection(a_set)
      a_set = JSON.parse(a_set.to_json) #Must parse as json, similar to redis queues. Stringifies symbol keys.
      begin
        response = MailRunner::ArchivistBot.establish_archive_link(a_set)
      rescue => e
       raise ArgumentError, "ERROR: Archive connection failed. Check your archive config options or disable."
      end
    end

  end
end