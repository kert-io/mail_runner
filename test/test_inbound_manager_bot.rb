require_relative 'helper'

class TestInboundManager < Minitest::Test
	
	#describe "Test Process Inbound Method" do
	#end

	describe "Inbound Manager::get_mail" do
		before do
			@inboundManager = MailRunner::InboundManagerBot
			@mailbox = "/var/mail/talkpost" #app 
			@webhook = "http://127.0.0.1:4000/talkpost"
		end
		context "when there is mail" do

			it "returns an object of type mail & empties mailbox after reading" do
		
				#insert test content into mailbox for test.
				`cp #{Dir[File.dirname(__FILE__)][0] + "/test_assets/test.email"} /var/mail/talkpost`
	
				object_returned = @inboundManager.get_mail(@mailbox)
				assert_instance_of Array, object_returned
				assert_equal 1, object_returned.length #confirms scrubs first empty item in array.
				assert_equal true, File.zero?(@mailbox)
			end
		end
	
		context "when there is no mail" do		
			it "does nothing if mailbox empty" do
				assert_silent {@inboundManager.get_mail(@mailbox)}
			end
		end
	end



	describe "Inbound Manager::read_mail" do
		before do
			@inboundManager = MailRunner::InboundManagerBot
			@raw_msg = File.read("#{Dir[File.dirname(__FILE__)][0] + "/test_assets/test.email"}")
		end
		it "takes raw message & returns an object of type mail" do
			assert_instance_of Mail::Message, @inboundManager.read_mail(@raw_msg)
		end
	end

	describe "Inbound Manager::deliver_mail" do
		before do 
			@inboundManager = MailRunner::InboundManagerBot
			@webhook = "http://127.0.0.1:4000/talkpost"
		end
		context "When webhook is valid" do
			it "successfully delivers mail " do
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/test.json'}"))
				assert_equal 200,  @inboundManager.deliver_mail(@webhook, parcel).code
			end
		end

		context "when webhook is invalid" do
			it "Returns true = added to queue" do
				@faulty_webhook = "http://127.0.0.1:4000/faulty_hook"
				@dead_webhook = "http://127.0.0.1:4000/faulty_hook"
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/empty.txt'}"))
				#Below 
				assert_equal true, @inboundManager.deliver_mail(@faulty_webhook, parcel)
				assert_equal true, @inboundManager.deliver_mail(@dead_webhook, parcel)
			end
		end
	end
end