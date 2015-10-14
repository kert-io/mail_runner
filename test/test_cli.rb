require_relative 'helper'

class TestCLI< Minitest::Test
	describe "test #parse_options" do
		before do
			@cli = MailRunner::CLI
		end

		it "returns a hash object when valid args entered" do
			assert_instance_of Hash, @cli.parse_options(["-m", "talkpost", "-w", "http://127.0.0.1:4000/talkpost"])
			assert_equal 2, @cli.parse_options(["-m", "talkpost", "-w", "http://127.0.0.1:4000/talkpost"]).size
		end

		it "Seems a worthless test to me..." do
			@cli.stub :daemonize, true do
				assert_equal true, @cli.daemonize
			end
		end
	end



	
end