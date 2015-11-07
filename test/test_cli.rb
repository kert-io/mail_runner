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

  describe 'launch with config file' do
    before do
    	@cli = MailRunner::CLI
      @options = @cli.parse_options(['mailrunner', '-c', './test/test_assets/test_config.yml'])
    end

    it 'takes a config path' do
      assert_equal './test/test_assets/test_config.yml', @options[:config]
    end

    it 'sets mailbox' do
      assert_equal 'test_mailbox', @options[:mailbox]
    end

    it 'sets webhook' do
      assert_equal 'localhost:4000/test_hook', @options[:webhook]
    end

    it 'sets daemon false by default' do
      assert_equal false, @options[:daemon]
    end

    it 'sets archive' do
      refute_nil  @options[:archive]
    end
    #Add subsections once archive complete

    it 'Does not set verbose' do
      refute @options[:verbose]
    end

    it 'sets logfile' do
      assert_equal '/home/user/mailrunner.log', @options[:logfile]
    end
  end

  describe "individual flags override config file" do
  	before do
    	@cli = MailRunner::CLI
			@options = @cli.parse_options(['mailrunner',
						                '-m', 'flag_mailbox',
						                '-w', 'localhost:4000/flag_hook',
						                '-d', 
						                '-a', true,
						                '-L', '/home/user/flag.log',
						                '-c', './test/test_assets/test_config.yml',
						                '-v', true])
	  end

	  it ' takes the config path' do
      assert_equal './test/test_assets/test_config.yml', @options[:config]
    end

    it 'uses flag mailbox' do
      assert_equal 'flag_mailbox', @options[:mailbox]
    end

    it 'uses flag webhook' do
      assert_equal 'localhost:4000/flag_hook', @options[:webhook]
    end

    it 'uses flag daemon setting' do
      assert_equal true, @options[:daemon]
    end

    it 'uses flag archive' do
      assert_equal true,  @options[:archive]
    end
    #Add subsections once archive complete

    it 'uses flag verbose' do
      assert_equal true, @options[:verbose]
    end

    it 'uses flag logfile' do
      assert_equal '/home/user/flag.log', @options[:logfile]
    end
  end
	
end