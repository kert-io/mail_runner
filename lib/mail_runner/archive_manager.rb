module MailRunner
  module ArchivistBot

    def self.add_to_archive_stack(msg, archive)
      que_packet = [msg, archive]
      $redis.lpush("archive_stack", que_packet.to_json)
      $logger.info("Archivist") { "#add_to_archive_stack:: email added to queue for processing later." }
    end

    def self.stack_height
      return $redis.llen("archive_stack")
    end

    def self.archive_stack
      $logger.info("Archivist") { "Stack Height:: #{stack_height}"}
      while stack_height > 0
        $logger.info("Archivist") { "#archive_stack:: Processing stack item:: #{stack_height}"}
        msg, archive = pop_from_stack

        if archive["destination"] == 'local'
          deliver_to_local_archive(msg, archive)
        else
          deliver_to_cloud_archive(msg, archive)
        end
      end
    end

    def self.pop_from_stack
      que_packet = $redis.blpop("archive_stack", :timeout => 5)[1] #timeout needed for MockRedis in Testing Env.
      $logger.info("Archivist") { "#item popped from stack for processing"}
      data = JSON::parse(que_packet)
      msg = data[0]
      archive = data[1]
      return msg, archive
    end

    def self.deliver_to_local_archive(msg, archive_opts)
      begin
        filename = name_msg(msg)
        target = File.open("#{archive_opts["local_archive"]}/#{filename}", 'w')
        target.write(msg)
        target.close()
        $logger.info("Archivist") { "#Message archived to local"}
      rescue => e
        $logger.error("Archivist") { "#deliver_to_local_archive:: failed: #{e.inspect}"}
        add_to_archive_stack(msg,archive_opts)
      end
    end

    def self.deliver_to_cloud_archive(msg, archive_opts)
      attempts = 0
      begin
        archive = establish_archive_link(archive_opts)
        filename = name_msg(msg)
        mimetype = "application/json"

        saved = archive.files.create :key => filename, :body => msg, :Content_type => mimetype
        $logger.info("Archivist") { "#Message archived to cloud"}
        return saved #explicit for testing
      rescue => e
        $logger.error("Archivist") { "#deliver_to_cloud_archive:: attempt #{attempts} failed: #{e.inspect}"}
        attempts += 1
        retry unless attempts > 1
        unless saved
          $logger.info("Archivist") { "Too many failed attempts, restacking msg."}
          add_to_archive_stack(msg,archive_opts)
        end
      end
    end

    def self.name_msg(msg)
      msg_id = JSON.parse(msg)[0]["msg"]["headers"]["Message-ID"]
      return "#{msg_id.gsub(/[#<$+%>!&*?=\/:@]/,'_')}.json"#clean illegal charaters
    end

    def self.establish_archive_link(archive_opts)
      service = new_storage_object(archive_opts)
      dir_name = archive_opts["directory"]
      archive_directory = service.directories.new :key => dir_name
      return archive_directory
    end

    def self.new_storage_object(archive_opts)
      options = format_options(archive_opts)
      Fog::Storage.new(options)
    end

    def self.format_options(archive_opts)
      provider = archive_opts["provider"].downcase

      options = {
        :provider => archive_opts["provider"] 
      }
      if provider == "rackspace"
        options[:"#{provider}_username"] = archive_opts["username"]     
        options[:"#{provider}_api_key"] = archive_opts["api_key"]
        options[:"#{provider}_region"] = archive_opts["region"]
      elsif provider == "aws"
        options[:"#{provider}_access_key_id"] = archive_opts["api_key"]
        options[:"#{provider}_secret_access_key"] = archive_opts["secret_key"]
      end

      return options
    end
    
  end
end
