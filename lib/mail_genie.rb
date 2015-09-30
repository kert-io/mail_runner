require_relative 'mail_genie/mail_getter_bot'
require_relative 'mail_genie/cli'

#require 'mail_genie/parser'
#require 'mail_genie/sender'

module MailGenie
	$redis = Redis.new(:host => 'localhost')
end

