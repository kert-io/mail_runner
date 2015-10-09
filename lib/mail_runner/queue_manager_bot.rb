module MailRunner

	module QueueManagerBot

    def self.add_to_mail_queue(webhook,parcel)
      que_packet = [webhook,parcel]
      $redis.lpush("mail_room", que_packet.to_json)
      puts "email added to queue for processing later.\n"
      return true
    end

    def self.queue_length
      return $redis.llen("mail_room")
    end
    
    def self.process_queue

      while queue_length > 0
        
        webhook, json_packet = pop_packet_from_queue
        
        deliver_mail(webhook, json_packet)
        
        #archive call
      end
    end

    def self.pop_packet_from_queue
      # Pop from Queue & organize
      key, que_packet = $redis.blpop("mail_room", :timeout => 5) 
            #timeout unnecessary in production because of while condition, but needed for MockRedis in Testing Env.
      
      data = JSON::parse(que_packet)
      
      webhook = data[0]
      json_packet = data[1]

      return webhook, json_packet
     end
     

    def self.deliver_mail(webhook, json_packet)
      begin
        BotHelpers::Runner.post_to_hook(webhook, json_packet)
      rescue 
        queued = self.add_to_mail_queue(webhook, json_packet)
        raise ArgumentError, "ERROR: \nServer appears to be down. Make sure the server is running."
      end
    end
  end

end