#!/usr/bin/ruby

class TaskPaperEntityEncodingExportPlugin < TaskPaperExportPlugin

	def process_text(item, run_text, output_type, before_conversion = true, options = {})
		if output_type == OUTPUT_TYPE_HTML
			run_text.gsub!('<', '&lt;')
			run_text.gsub!('>', '&gt;')
			run_text.gsub!(/&(?!amp;)/, '&amp;')
		end
		
		return run_text
	end
	
end
