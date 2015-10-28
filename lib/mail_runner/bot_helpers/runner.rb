module BotHelpers

	module Runner
    def self.get_contents_from_mailbox(mailbox)
      unless File.zero?(mailbox)

        raw_contents = File.read(mailbox)
        raw_mail = raw_contents.split(BotHelpers::Helpers::REGEX_POSTFIX_MESSAGE_DELIMITER)

        unless raw_mail.size <= 1
          raw_mail.shift #remove empty from split
        end

        #Clean mailbox.
        raw = File.open(mailbox, 'r+')
        raw.truncate(0) 
        raw.close
        $logger.info("Runner") { "#get_contents_from_mailbox:: #{raw_mail.size} Mail messagess retrieved"}
        return raw_mail
      end
    end

    def self.post_to_hook(webhook, parcel)
      begin
      	response = RestClient.post webhook, :mail_runner_envelope => parcel, :content_type => :json, :accept => :json
        
        $logger.info("Runner") { 
          "#post_to_hook::response code:#{response.code}\n" + 
          "\tEmail from: #{JSON.parse(parcel)[0]['msg']['from_email']}  to: #{JSON.parse(parcel)[0]['msg']['email']}\n" + 
          "\tPosted to: #{webhook}"
        }
        $logger.debug("Runner") { "#post_to_hook::response header:#{response.headers}"}
        
        MailRunner.manager_bot.update_webhook_status("live")
      rescue 
        $logger.error("Runner") { "#post_to_hook::ABORT: Server appears to be down. Make sure the server is running."}
        MailRunner.manager_bot.update_webhook_status("down")
    		raise ArgumentError
    	end
      
      unless response.code == 200
    		$logger.error("Runner") { "#post_to_hook::ABORT: Invalid Webhook. Response not 200. NOTE, Must respond to http HEAD method."}
        raise
    	end
      return response
    end
    
  end

end