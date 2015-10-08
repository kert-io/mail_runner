module MailRunner

	module InboundManagerBot
    
    def self.process_inbound(mailbox, webhook, archive)
      raw_mail = get_mail(mailbox)
      
      unless raw_mail.nil?
        raw_mail.each do |raw_msg|    

          mail = read_mail(raw_msg)

          json_packet = BotHelpers::Helpers.convert_raw_mail_to_json(mail)
          
          deliver_mail(webhook, json_packet)
          
          if archive == true && queued.nil?
            puts "we will archive email.\n"
          end
          
        end
      end
    end

    def self.get_mail(mailbox)
      BotHelpers::Runner.get_contents_from_mailbox(mailbox) 
    end
    
    def self.read_mail(raw_msg)
      Mail.read_from_string(raw_msg)
    end

    def self.deliver_mail(webhook, json_packet)
      begin
        BotHelpers::Runner.post_to_hook(webhook, json_packet)
      rescue Exception => msg 
        #interrupt exception here, so rest of inbound mail can be processed and added to queue.
        #otherwise, it will be lost.
        puts msg.inspect
        queued = MailRunner::QueueManagerBot.add_to_mail_queue(webhook, json_packet)
      end
    end

  end

end