require_relative 'helper'


class TestQueueManager < Minitest::Test

	describe "Queue Manager::add_mail_to_queue" do
		before do
			$redis.del("mail_room") # make sure starting with empty list
			@queueManager = MailRunner::QueueManagerBot
			@parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/empty.txt'}"))
			@webhook = "http://127.0.0.1:4000/talkpost"

		end
		it 'successfully adds web hook & parcel to redis queue' do
			assert_equal true, @queueManager.add_to_mail_queue(@webhook, @parcel)
			assert_equal 1, $redis.llen("mail_room")
		end

		#it "preserves the content ty"
	end

	describe "Queue Manager::pop_packet_from_queue" do
		before do
			$redis.del("mail_room") # make sure starting with empty list
			@queueManager = MailRunner::QueueManagerBot

			webhook = "http://127.0.0.1:4000/talkpost"
			mail = Mail.read("#{Dir[File.dirname(__FILE__)][0] + "/test_assets/test.email"}")
			@helper = BotHelpers::Helpers
			que_packet = [webhook, @helper.convert_raw_mail_to_json(mail)]
			
			$redis.lpush("mail_room", que_packet.to_json)
		end


		it "returns an array with the hook & json email packet" do
			def valid_json? json_  
			  JSON.parse(json_)  
			  return true  
			rescue JSON::ParserError  
			  return false  
			end 
			
			returned_data = @queueManager.pop_packet_from_queue
			assert_equal 2, returned_data.size
			assert_equal "http://127.0.0.1:4000/talkpost", returned_data[0]
			assert_equal true, valid_json?(returned_data[1])
		end

	end

	describe "Queue Manager::deliver_mail" do
		before do 
			@queueManager = MailRunner::QueueManagerBot
			@webhook = "http://127.0.0.1:4000/talkpost"
		end
		context "When webhook is valid" do
			it "successfully delivers mail " do
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/test.json'}"))
				assert_equal 200,  @queueManager.deliver_mail(@webhook, parcel).code
			end
		end

		context "when webhook is invalid" do
			it "Returns true = added to queue" do
				@faulty_webhook = "http://127.0.0.1:4000/faulty_hook"
				@dead_webhook = "http://127.0.0.1:4000/faulty_hook"
				parcel = File.read(("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/empty.txt'}"))
				#Below 
				assert_raises(ArgumentError) {@queueManager.deliver_mail(@faulty_webhook, parcel)}
				assert_raises(ArgumentError) {@queueManager.deliver_mail(@dead_webhook, parcel)}
			end
		end
	end

end