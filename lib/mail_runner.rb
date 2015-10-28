Dir[File.dirname(__FILE__) + '/mail_runner/*.rb'].each {|file| require file }

module MailRunner
	$redis = Redis.new(:host => 'localhost')
	def self.manager_bot
  	defined?(@manager_bot) ? @manager_bot : initialize_manager_bot
  end

  def self.initialize_manager_bot
  	@manager_bot = MailRunner::ManagerBot.new
  	logger.debug { "ManagerBot initialized."}
  	return @manager_bot
  end

  def self.logger
    MailRunner::Logging.logger
  end

  def self.logger=(log)
    MailRunner::Logging.logger = log
  end
end

