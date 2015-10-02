#####################
# Several tests require a live server behind the test webhook.  
# will cause sveral fails if not. Must be Post method.



######################
require_relative 'helper'
require_relative '../lib/mail_runner.rb'

class TestMailGetter < Minitest::Test
	
	####### Top Level Call Tests ##########
	describe 'Mail Getter bot initialize' do
		before do
			@bot = MailRunner::MailGetterBot.new
		end

		it "Getter Bot & atributes exist" do
			assert_instance_of MailRunner::MailGetterBot, @bot 
			assert_equal nil, @bot.mailbox
			assert_equal nil, @bot.webhook 
			assert_equal false, @bot.archive
		end

		it "includes BotHelpers" do
		end
	end

	describe "Parse Options method" do
		before do
			@bot = MailRunner::MailGetterBot.new
			@opts = {:mailbox => "box_name", :webhook => "webhook/path"}
		end

		it "assigns passed arguments as getter bot attributes" do
			@bot.parse_options(@opts)
			assert_equal "/var/mail/box_name", @bot.mailbox
			assert_equal "webhook/path", @bot.webhook
			assert_equal false, @bot.archive
		end

		it "archive = true if passed archive argument" do
			@opts[:archive] = "true"
			@bot.parse_options(@opts)
			assert_equal true, @bot.archive
		end
	end

	describe "Run Method" do
		before do
			@bot = MailRunner::MailGetterBot.new
			@bot.mailbox = "/var/mail/root" #app 
			@bot.webhook = "http://127.0.0.1:4000/talkpost"
		end

	end
 ########################################


 ####### BotHelpers::Tests ###########
	describe "test BotHelpers:: Tests" do
		before do
			@opts ={
				:mailbox => "/var/mail/root", #app 
				:webhook => "http://127.0.0.1:4000/talkpost"
			}
			@test = BotHelpers::Tests
		end

		#all_args?
		it "Error - .all_args_included? if arguments less than 2" do
			@opts.shift
			assert_raises(ArgumentError) {@test.all_args_included?(@opts)}
		end

		it "Error - .all_args_included? if arguments more than 3" do
			@opts[:three] = "three"
			@opts[:four] = " four"
			assert_raises(ArgumentError) {@test.all_args_included?(@opts)}
		end

		it "Passes - .all_args_included? if 2 or 3 arguments." do
			assert_silent {@test.all_args_included?(@opts)}
			@opts[:archive]=true
			assert_silent {@test.all_args_included?(@opts)}
		end

		#test_mailbox
		it "error - .test_mailbox if doesn't exist" do
			assert_raises(ArgumentError) {@test.test_mailbox("no_mailbox")}
		end

		it "Passes - .test_mailbox if exists" do
			assert_silent {@test.test_mailbox(@opts[:mailbox])}
		end

		#test_webhook
		it "Passes - .test_webook if returns 200" do
			assert_silent {@test.test_webhook(@opts[:webhook])}
		end

		it "fails - .test_webook if returns not 200" do
			assert_raises(ArgumentError) {@test.test_webhook("http://127.0.0.1:4000/faulty_hook")}
		end
	end
 ########################################


 ####### BotHelpers::Runner ###########
 	describe "test BotHelpers:: Runner" do
		context "method : get_contents_from_email" do
			before do
				@mailbox = "/var/mail/talkpost" #app 
				@webhook = "http://127.0.0.1:4000/talkpost"
				@runner = BotHelpers::Runner
			end

			#get_contents_from_email
			context "when there is mail" do

				it "returns an object of type mail & empties mailbox after reading" do
			
					#insert test content into mailbox for test.
					`cp #{Dir[File.dirname(__FILE__)][0] + "/test_assets/test.email"} /var/mail/talkpost`
		
					#assert_instance_of Mail::Message, @runner.get_contents_from_mailbox(@mailbox)
					object_returned = @runner.get_contents_from_mailbox(@mailbox)
					assert_instance_of Array, object_returned
					assert_equal 1, object_returned.length #confirms scrubs first empty item in array.
					assert_equal true, File.zero?(@mailbox)
				end
			end

			context "when there is no mail" do		
				it "does nothing if mailbox empty" do
					assert_silent {@runner.get_contents_from_mailbox(@mailbox)}
				end
			end

		end
		context "method : Post_to_hook" do
			before do
				@webhook = "http://127.0.0.1:4000/talkpost"
				@runner = BotHelpers::Runner
			end
			it "successfully posts if packet has contents to webhook" do
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/test.json'}"))
				assert_equal 200,  @runner.post_to_hook(@webhook, parcel).code
			end

			it "Returns and error if server down or response not 200" do
				@faulty_webhook = "http://127.0.0.1:4000/faulty_hook"
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/empty.txt'}"))
				assert_raises(ArgumentError) {@runner.post_to_hook(@faulty_webhook, parcel)}
			end
		end

		context "method: add mail to queue" do
			it "do we really need to test this one?" do
			end
		end


	end

 ########################################


 ####### BotHelpers::Helpers ###########
	describe "test BotHelpers:: Helpers" do
		before do
			@helper = BotHelpers::Helpers
		end

 		context "method : convert_raw_mail_to_json" do
 			before do
 				@mail = Mail.read("#{Dir[File.dirname(__FILE__)][0] + "/test_assets/test.email"}")
 			end

			it "returns valid json " do
				def valid_json?(j)
				  JSON.parse(j)  
				  return true  
				rescue JSON::ParserError  
				  return false  
				end 
				
				assert_equal true, valid_json?(@helper.convert_raw_mail_to_json(@mail))
			end
		end

		context "method : parse_attachments" do
			before do
 				@mail = Mail.read("#{Dir[File.dirname(__FILE__)][0] + "/test_assets/with_attachments.email"}")
 				@inline_mail = Mail.read("#{Dir[File.dirname(__FILE__)][0] + "/test_assets/inline_attachments.email"}")
 			end

			it "returns a hash of 2 arrays" do
				assert_instance_of Hash, @helper.parse_attachments(@mail.attachments)
				assert_equal 2, @helper.parse_attachments(@mail.attachments).size
			end

			it "returns content in i_array if inline attachment" do
				assert_equal 1, @helper.parse_attachments(@inline_mail.attachments)[:i_array].size
				assert_equal 0, @helper.parse_attachments(@inline_mail.attachments)[:a_array].size
			end

			it "returns conent in a_array if not inline attachment" do
				assert_equal 0, @helper.parse_attachments(@mail.attachments)[:i_array].size
				assert_equal 1, @helper.parse_attachments(@mail.attachments)[:a_array].size
			end
		end


	end
########################################

	
end