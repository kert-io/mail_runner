# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mail_genie/version"

Gem::Specification.new do |s|
  s.name        = "mail_genie"
  s.version     = MailGenie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kert Heinecke"]
  s.email       = ["kert@sakuru.io"]
  s.homepage    = "https://github.com/kert-io/mailGenie"
  s.summary     = %q{Gem for inbound mail. Creates separate worker process for delivery to app. Includes a bunch mail processing helpers inside app}
  s.description = %q{Gem for inbound mail. Creates separate worker process for delivery to app. Includes a bunch mail processing helpers inside app}
  s.license     = 'MIT'

  #s.files         = `git ls-files`.split("\n") #only works once committed to git
  s.files       = ["lib/mail_genie.rb", "lib/mail_genie/mail_getter_bot.rb", "lib/mail_genie/bot_helpers.rb"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  

  s.add_dependency "mail", "~> 2.5.4"
  s.add_dependency "json", "~> 1.8.1"
  s.add_dependency "rest-client", "~> 1.8.0"


  s.add_development_dependency 'rake', "~> 10.3.2"
  s.add_development_dependency 'minitest/autorun'
  s.add_development_dependency 'minitest/spec'
  s.add_development_dependency 'minitest/reporters'
  s.add_development_dependency 'minitest-spec-context'
  s.add_development_dependency 'rake/testtask'
end