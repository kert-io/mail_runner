module BotHelpers

	module Runner
    def self.get_contents_from_mailbox(mailbox)
      unless File.zero?(mailbox)

        raw_contents = File.read(mailbox)
        raw_mail = raw_contents.split(BotHelpers::Helpers::REGEX_POSTFIX_MESSAGE_DELIMITER)
        puts raw_mail.size.inspect
        unless raw_mail.size <= 1
          raw_mail.shift #remove empty from split
        end

        #Clean mailbox.
        raw = File.open(mailbox, 'r+')
        raw.truncate(0) 
        raw.close
        
        return raw_mail
      end
    end

    def self.post_to_hook(webhook, parcel)
      begin
      	response = RestClient.post webhook, :mail_runner_envelope => parcel, :content_type => :json, :accept => :json
        puts "#{response.code}"
        puts "#{response.headers}\n\n"
        MailRunner.manager_bot.update_webhook_status("live")
      rescue 
        MailRunner.manager_bot.update_webhook_status("down")
    		raise ArgumentError, "ERROR: Server appears to be down. Make sure the server is running."
    	end
      
      unless response.code == 200
    		raise ArgumentError, "ERROR: Invalid Webhook. NOTE, Must respond to http HEAD method."
    	end
      return response
    end
    
  end

end