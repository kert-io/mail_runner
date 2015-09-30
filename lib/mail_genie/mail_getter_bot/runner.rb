module BotHelpers

	module Runner
    def self.get_contents_from_mailbox(mailbox)
      unless File.zero?(mailbox)

        raw_contents = File.read(mailbox)
        raw_mail = raw_contents.split(BotHelpers::Helpers::REGEX_POSTFIX_MESSAGE_DELIMITER)
        raw_mail.shift #remove empty from split

        #Clean mailbox.
        raw = File.open(mailbox, 'r+')
        raw.truncate(0) 
        raw.close
        
        return raw_mail
      end
    end

    def self.post_to_hook(webhook, parcel)
      begin
      	response = RestClient.post webhook, :local_mail_event => parcel, :content_type => :json, :accept => :json
        puts "#{response.code}"
        puts "#{response.headers}\n\n"
      rescue 
    		raise ArgumentError, "ERROR: \nServer appears to be down. Make sure the server is running."
    	end
      
      unless response.code == 200
    		raise ArgumentError, "ERROR: Invalid Webhook. NOTE, Must respond to http HEAD method."
    	end
      return response
    end

    def self.add_to_mail_queue(webhook,parcel)
      que_packet = [webhook,parcel]
      $redis.lpush("mail_room", que_packet.to_json)
      puts "email added to queue for processing later.\n"
      return true
    end
    
  end

end