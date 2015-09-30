ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/spec'
require "minitest/reporters"
require 'minitest-spec-context'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(:color => true)]