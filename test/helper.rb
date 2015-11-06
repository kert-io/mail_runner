ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/spec'
require "minitest/reporters"
require 'minitest-spec-context'
require 'mock_redis'
require_relative '../lib/mail_runner.rb'

#Use Mock Redis during testing - Can't use any blocking methods!!
$redis = MockRedis.new(:host => 'localhost')
$mad_statter = MailRunner::MadStatter
$logger = MailRunner::Logging.logger #needed or causes errors in tests
$logger.level = Logger::FATAL #turn off logging info during tests

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(:color => true)]