module BotHelpers
  module Helpers
    #Based on Mbox protocol. maildir not yet supported.
    #? in ?\.?[a-zA-Z]{2,4} makes compatible with local mail and internal process logging.
    # working test case: http://rubular.com/r/N5iHbxk1q1
    REGEX_POSTFIX_MESSAGE_DELIMITER =/^From\W\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+?\.?[a-zA-Z]{2,4}\b\W{1,}[a-zA-Z]{3}\W{1,}\w{3}\W{1,}\d{1,2}\W\d{2}:\d{2}:\d{2}\W\d{4}\n/
  	def self.print_monitoring_started_msg(bot)
  		$logger.info("Helpers") { "mailbox: #{bot.mailbox}" }
  		$logger.info("Helpers") { "path: #{bot.webhook}"}
      unless bot.archive.nil?
        if bot.archive[:destination] == 'cloud'
  		  $logger.info("Helpers") {"archive: #{bot.archive[:provider]} :: #{bot.archive[:directory]}"}
        else
          $logger.info("Helpers") {"archive: #{bot.archive[:destination]} :: #{bot.archive[:local_archive]}"}
        end
      end
  		puts "Getter Bot is on the Job!" 
  	end

    def self.convert_raw_mail_to_json(mail)
      mail_array = []
      header = parse_header(mail.header)
      from = parse_from(header[:From])
      attachments = parse_attachments(mail.attachments)
      
      msg = {
        :raw_msg => mail.to_s, 
        :headers => header,
        :from_email => from[1],
        :from_name => from[0],
        :to => header[:To],
        :email => header[:'X-Original-To'],
        :subject => header[:Subject],
        :tags => '',
        :sender => header[:Sender],
        :spam_report => 'spam report'
      }

      msg[:text] = mail.text_part.decoded unless mail.text_part.nil?
      msg[:html] = mail.html_part.decoded unless mail.html_part.nil?
      #omitted unless attachments 
      msg[:attachments] = attachments[:a_array] unless attachments[:a_array].empty?
      msg[:images] = attachments[:i_array] unless attachments[:i_array].empty?


      hash = {
        :msg => msg
      }

      mail_array << hash
      return  mail_array.to_json
    end


    def self.parse_header(header_contents)
      hash = {}
      header = header_contents.to_s.split(/\r\n/)
      header.each do |h|
        parts = h.split(/:/, 2)
        unless parts[0].nil? or parts[1].nil?
          key = parts[0].strip.to_sym
          next if key =~ /Return-Path/i
          value = parts[1].strip
          hash[key] = parts[1].strip
        end
      end
      return hash
    end

    def self.parse_from(from)
      from = from.split(/</)
      from[0] = from[0].strip
      from[1] = from[1].strip.gsub(/>/,'')
      return from
    end

    def self.parse_attachments(attachments)
      a_array = []
      i_array = []
      attachments.each do |att|
        disposition = att.content_disposition.split(/;/)[0]
        item = {
          :name => att.filename,
          :type => att.content_type.split(/;/)[0],
          :content => Base64.encode64(att.body.decoded),
          :base64 => true,
          :attachment_id => att.content_id
        }
        if disposition == 'inline'
          i_array << item
        else
          a_array << item
        end
      end
      return {:a_array => a_array, :i_array => i_array}
    end

  end

end

