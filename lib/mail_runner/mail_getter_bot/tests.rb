module BotHelpers

	module Tests  #series of initial command validation tests on launch. 
  	def self.all_args_included?(args)
    	if args[:mailbox].nil? or args[:webhook].nil?
    		raise ArgumentError, 'You must include mailbox & webhook minimum. Archive argument is optional.' 
  		end
  		if args.size > 3
    		raise ArgumentError, 'You can only include mailbox, webhook & Archive argument. 3 max!' 
  		end
	  		#?test format of mailbox?
	  		#? test valid webhook format?
  	end
  	
  	def self.test_mailbox	(path)
    	unless File.file?(path)
    		raise ArgumentError, 'ERROR: Mailbox not valid' 
    	end
    end

    def self.test_webhook(url) 
    	begin
    		response = RestClient.head url
    	rescue 
    		raise ArgumentError, "ERROR: \nMake sure the server is running and the webhook exists.\nNOTE:  Server must respond to http HEAD method.\nSee README.md for proper setup.\n"
    	end
    	unless response.code == 200
    		raise ArgumentError, "ERROR: Invalid Webhook. NOTE, Must respond to http HEAD method."
    	end
    end
  end

end