module BotHelpers

  module Runner
    def self.get_contents_from_mailbox(mailbox)
      unless File.zero?(mailbox)

        file = File.open(mailbox, 'r+')
        file.flock(File::LOCK_EX)     #lock file so no other process uses it while open. NOTE: lock before read, so other locks can finish executing.
        raw_contents = file.read      # read contents to var so we can release lock and process later
        file.truncate(0)              #clear mbox file once read
        file.close                    #close file to release lock prior to processing contents.
      
        #porcess Mail content into array of individual messages
        raw_mail = raw_contents.split(BotHelpers::Helpers::REGEX_POSTFIX_MESSAGE_DELIMITER)
        unless raw_mail.size <= 1
          raw_mail.shift #remove empty from split
        end

        $logger.info("Runner") { "#get_contents_from_mailbox:: #{raw_mail.size} Mail messagess retrieved"}
        return raw_mail
      end
    end

    def self.post_to_hook(webhook, parcel)
      begin
      	response = RestClient.post webhook, :mail_runner_envelope => parcel, :content_type => :json, :accept => :json
        
        $mad_statter.incr_stat("mail delivered")
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