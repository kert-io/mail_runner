require_relative 'mail_runner/mail_getter_bot'
require_relative 'mail_runner/cli'

module MailRunner
	$redis = Redis.new(:host => 'localhost')
end

