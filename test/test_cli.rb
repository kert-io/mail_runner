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
	describe "demonization upon start" do

		#create some set up where it makes sure server is down and test -d flag
		it "does not daemonize if the mailbox or webhook is invalid" do
			
		end
	end

	describe 'with logfile' do
      before do
      	@cli = MailRunner::CLI
        @tmp_log_path = '/tmp/mailrunner.log'
        @options = @cli.parse_options(['mailrunner', '-L', @tmp_log_path])
        @logger = Logger.new(@options[:logfile]) #Bypass logger in helper file so can create new one with tmp path
      end
      after do 
      	File.unlink @tmp_log_path if File.exist?(@tmp_log_path)
      end

      it 'sets the logfile path' do
        assert_equal @tmp_log_path, @options[:logfile]
      end

      it 'creates and writes to a logfile' do
        @logger.info('test message')
        assert_match(/test message/, File.read(@tmp_log_path), "didn't include the log message")
      end

      it 'appends messages to a logfile' do
        File.open(@tmp_log_path, 'w') do |f|
          f.puts 'Existing log message'
        end
       	@logger.info('test message')

        log_file_content = File.read(@tmp_log_path)
        assert_match(/Existing log message/, log_file_content, "didn't include the old message")
        assert_match(/test message/, log_file_content, "didn't include the new message")
      end
    end


	
end