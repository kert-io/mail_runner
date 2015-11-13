#####################



######################
require_relative 'helper'

class TestArchivist < Minitest::Test
	
	####### Top Level Call Tests ##########
	describe"Archivist::stack_height" do
		before do
			@archivist = MailRunner::ArchivistBot
		end
		it "returns an integer" do
			assert_instance_of Fixnum, @archivist.stack_height
		end
	end

	describe "Archivist::deliver_to_local_archive" do
		before do
			`mkdir /tmp/local_test_archive`
			$redis.del("archive_stack") #zero list
			@archivist = MailRunner::ArchivistBot
			@filename = "_1447427485391-46840973-67af09f8-7a989c0d_mixmax.com_.json"
			@msg = File.read("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/' + @filename}")
			@archive_opts = {"local_archive" => '/tmp/local_test_archive'}
		end
		after do
			`rm -rf /tmp/local_test_archive`
		end
		context 'when local path is valid' do
			it "successfully adds msg to archive" do
				assert_silent { @archivist.deliver_to_local_archive(@msg, @archive_opts) }
				assert_equal true, File.file?("#{@archive_opts["local_archive"]}" + "/" + "#{@filename}")
			end
		end

		context 'when local path is invalid' do
			it "adds msg to archive_stack" do
				@archivist.deliver_to_local_archive(@msg, "/home/invalid_path")
				assert_equal 1, $redis.llen('archive_stack')
			end
		end
	end

	describe "Archivist::deliver_to_cloud_archive" do
		before do
			$redis.del("archive_stack") #zero list
      @archive_opts = JSON.parse(File.read("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/archive_opts.json'}"))[0]
			@msg = File.read("#{Dir[File.dirname(__FILE__)][0] + '/test_assets/_1447427485391-46840973-67af09f8-7a989c0d_mixmax.com_.json'}")
			@archivist = MailRunner::ArchivistBot
			#set for Mocking only. 
			Fog.mock!
			#Must create fake directory in mock stub
			service = @archivist.new_storage_object(@archive_opts)
			service.directories.create :key => 'raw_msg_archive'
		end

		context "when cloud archive credentials valid" do
			it "successfully adds msg to archive" do
				assert_instance_of Fog::Storage::Rackspace::File, @archivist.deliver_to_cloud_archive(@msg, @archive_opts)
				assert_equal 0, $redis.llen('archive_stack') #doesn't hit stack
			end
		end

		context "When cloud archive credentials invalid" do
			before do
				@archive_opts["api_key"] = nil
				@archivist.deliver_to_cloud_archive(@msg, @archive_opts)
			end
			it "adds msg to archive_stack" do
				assert_equal 1, $redis.llen('archive_stack')
			end
		end
	end

	describe 'Archivist::establish_archive_link' do
		it 'Test included under: test BotHelpers:: Tests :: archive_tests' do
		end
	end

	describe 'Archivist::format_options' do
		it 'Test included under: test BotHelpers:: Tests :: archive_tests' do
		end
	end

 ########################################

end