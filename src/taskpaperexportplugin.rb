#!/usr/bin/ruby

class TaskPaperExportPlugin
	OUTPUT_TYPE_TEXT = 0 # textual output, such as a TaskPaper-format file
	OUTPUT_TYPE_HTML = 1 # HTML output
	OUTPUT_TYPE_JSON = 2 # JSON output ( http://json.org )
	
	RUN_TYPE_TEXT = 0 # any plain-text run within an item
	RUN_TYPE_TAG_NAME = 1
	RUN_TYPE_TAG_VALUE = 2
	RUN_TYPE_LINK = 3
	
	def process_run(item, run_text, run_type, output_type, before_conversion = true, options = {})
		return run_text
	end
	
	def process_text(item, run_text, output_type, before_conversion = true, options = {})
		return process_run(item, run_text, RUN_TYPE_TEXT, output_type, before_conversion, options)
	end
	
	def process_link(item, run_text, output_type, before_conversion = true, options = {})
		return process_run(item, run_text, RUN_TYPE_LINK, output_type, before_conversion, options)
	end
	
	def process_tag_name(item, run_text, output_type, before_conversion = true, options = {})
		return process_run(item, run_text, RUN_TYPE_TAG_NAME, output_type, before_conversion, options)
	end
	
	def process_tag_value(item, run_text, output_type, before_conversion = true, options = {})
		return process_run(item, run_text, RUN_TYPE_TAG_VALUE, output_type, before_conversion, options)
	end
end
