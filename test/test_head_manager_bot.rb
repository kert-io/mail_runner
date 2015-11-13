#####################
# Several tests require a live server behind the test webhook.  
# will cause several fails if not. Must be Post method.



######################
require_relative 'helper'

class TestHeadManager < Minitest::Test
	
	####### Top Level Call Tests ##########
	describe 'MR Manager::MailRunner Manager initialize' do
		before do
			@bot = MailRunner.initialize_manager_bot
		end

		it "MailRunner Manager & atributes exist" do
			assert_instance_of MailRunner::ManagerBot, @bot 
			assert_equal nil, @bot.mailbox
			assert_equal nil, @bot.webhook 
			assert_equal nil, @bot.archive
		end

		it "includes BotHelpers" do
		end
	end

	describe "MR Manager::Parse Options method" do
		before do
			@bot = MailRunner.initialize_manager_bot
			@opts = {:mailbox => "box_name", :webhook => "webhook/path"}
		end

		it "assigns passed arguments as getter bot attributes" do
			@bot.parse_options(@opts)
			assert_equal "/var/mail/box_name", @bot.mailbox
			assert_equal "webhook/path", @bot.webhook
			assert_equal nil, @bot.archive
		end

		it "archive = true if passed archive argument" do
			@opts[:archive] = true
			@bot.parse_options(@opts)
			assert_equal true, @bot.archive
		end
	end

	describe "MR Manager::Run Method" do
		before do
			@bot = MailRunner.initialize_manager_bot
			@bot.mailbox = "/var/mail/root" #app 
			@bot.webhook = "http://127.0.0.1:4000/talkpost"
		end

	end
 ########################################

end