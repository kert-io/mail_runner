module MailRunner
	module MadStatter

		#get_stats
		#get_stat
		def self.incr_stat(stat)
			case stat
				###Totals###
				when "mail delivered"
					$redis.incr("MR::mail_processed")
				when "runner launched"
					$redis.incr("MR::launches")
				#errors
				#added_queue
				#removed_queue
			end
		end
		
  end
end