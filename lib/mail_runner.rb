Dir[File.dirname(__FILE__) + '/mail_runner/*.rb'].each {|file| require file }

module MailRunner
	def self.set_globals
    $logger = MailRunner::Logging.logger
    $mad_statter = MailRunner::MadStatter
    $redis = Redis.new(:host => 'localhost')
  end

	def self.manager_bot
  	defined?(@manager_bot) ? @manager_bot : initialize_manager_bot
  end

  def self.initialize_manager_bot
  	@manager_bot = MailRunner::ManagerBot.new
  	$logger.debug { "ManagerBot initialized."}
  	return @manager_bot
  end
end

