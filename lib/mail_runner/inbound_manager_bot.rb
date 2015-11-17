module MailRunner

  module InboundManagerBot
    
    def self.process_inbound(mailbox, webhook, archive=nil)
      raw_mail = get_mail(mailbox)
      
      unless raw_mail.nil?
        raw_mail.each do |raw_msg|    

          mail = read_mail(raw_msg)

          json_packet = BotHelpers::Helpers.convert_raw_mail_to_json(mail)
          
          deliver_mail(webhook, json_packet)

          #Mail archived regardless of delivery errors.
          #Delayed mail processed by queue manager, so only archived once on initial pickup. 
          if archive   
            MailRunner::ArchivistBot.add_to_archive_stack(json_packet, archive)
          end
        end
      end
    end

###Delegation Methods###

    def self.get_mail(mailbox)
      BotHelpers::Runner.get_contents_from_mailbox(mailbox) 
    end
    
    def self.read_mail(raw_msg)
      Mail.read_from_string(raw_msg)
    end

    def self.deliver_mail(webhook, json_packet)
      begin
        BotHelpers::Runner.post_to_hook(webhook, json_packet)
      rescue Exception 
        #interrupt exception here, so rest of inbound mail can be processed and added to queue.
        #otherwise, it will be lost.
        MailRunner::QueueManagerBot.add_to_mail_queue(webhook, json_packet)
      end
    end


  end
end