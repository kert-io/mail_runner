require_relative 'helper'

class TestBotHelpers < Minitest::Test

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

		#Create test for other arguments like daemonize, log, etc

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

	describe "test BotHelpers:: Tests :: archive_tests" do
		context "method : test_archive" do
			before do
				@arch_opts ={:destination => 'random'}
				@test = BotHelpers::Tests
			end
			it "raises argument error if destination not cloud or local" do
				assert_raises(ArgumentError) {@test.test_archive(@arch_opts)}
			end
		end

		context "method : test_local_archive" do
			before do
				`mkdir /tmp/temp_archive`
				@arch_opts = {
					:destination =>  'local',
					:local_archive => '/tmp/temp_archive'
				}
				@test = BotHelpers::Tests
			end
			after do 
				`rm -rf /tmp/temp_archive`
			end

			it "is silent if directory exists" do
				assert_silent {@test.test_local_archive(@arch_opts)}
			end

			it "raises error if directory doesn't exist" do 
				@arch_opts[:local_archive] = '/tmp/other_archive'
				assert_raises(ArgumentError) {@test.test_local_archive(@arch_opts)}
			end

		end

		context "method : test_cloud_archive_connection" do
			before do
				require '~/.apikeys'
				#Set to test live Rackspace account. pulls in keys from require location above. 
				#to test live, make .apikeys file in home directory and add keys there to keep out of git.
				#to test only stub, uncomment #Fog.mock! & change username & api_key in arch_opts
				@test = BotHelpers::Tests
				#Fog.mock!
				@arch_opts = {
					:destination => 'cloud',
					:provider => 'Rackspace',
  				:username => "#{RACKSPACE_USERNAME}",             
			 	 	:api_key => "#{RACKSPACE__API_KEY}",             
					:secret_key => "sdsd34d334",                             
					:directory => 'raw_msg_archive' 
				}
			end
			it "successfully connects to cloud archive" do
				assert_silent {@test.test_cloud_archive_connection(@arch_opts)}
			end

			it "raises error if fails connect to cloud archive" do
				@arch_opts[:api_key] = nil
				assert_raises(ArgumentError) {@test.test_cloud_archive_connection(@arch_opts)}
			end

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

			it "Returns an error if server down or response not 200" do
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