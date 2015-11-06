module MailRunner
	module MadStatter

		#get_stats
		def get_stat(stat)
			case stat
				when "session number"
					$redis.get("MR::sessions")
			end
		end
		def self.incr_stat(stat)
			case stat
				###Totals###
				when "mail delivered"
					$redis.incr("MR::mail_processed")
				when "runner launched"
					$redis.incr("MR::sessions")
				#errors
				#added_queue
				#removed_queue
			end
		end
		
  end
end