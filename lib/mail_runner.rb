#require_relative 'mail_runner/mail_getter_bot'
#require_relative 'mail_runner/queue_manager_bot'
#require_relative 'mail_runner/cli'
Dir[File.dirname(__FILE__) + '/mail_runner/*.rb'].each {|file| require file }

module MailRunner
	$redis = Redis.new(:host => 'localhost')

	def self.manager_bot
  	defined?(@manager_bot) ? @manager_bot : initialize_manager_bot
  end

  def self.initialize_manager_bot
  	@manager_bot = MailRunner::ManagerBot.new
  	return @manager_bot
  end

end

