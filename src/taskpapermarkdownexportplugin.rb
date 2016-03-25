#!/usr/bin/ruby

class TaskPaperMarkdownExportPlugin < TaskPaperExportPlugin

	def process_text(item, run_text, output_type, before_conversion = true, options = {})
		if output_type == OUTPUT_TYPE_HTML
			
			# Emphasis _..._, __...__, *...*, **...**
			emphasis_regexp = /([*]{1,2})([^*]+?)[*]{1,2}|([_]{1,2})([^_]+?)[_]{1,2}/i
			while emphasis_regexp =~ run_text
				matches = run_text.to_enum(:scan, emphasis_regexp).map { Regexp.last_match }
				matches.reverse.each do |match|
					level = ((match[1] != nil) ? match[1] : match[3]).length
					text = (match[1] != nil) ? match[2] : match[4]
					range = Range.new(match.begin(0), match.end(0), true)
					tag = (level == 1) ? "em" : "strong"
					run_text[range] = "<#{tag}>#{text}</#{tag}>"
				end
			end
			
			# Backtick code spans `...`
			backticks_regexp = /\`([^\`]+)\`/i
			matches = run_text.to_enum(:scan, backticks_regexp).map { Regexp.last_match }
			matches.reverse.each do |match|
				text = match[1]
				# Encode some entities
				text = text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
				range = Range.new(match.begin(0), match.end(0), true)
				tag = "code"
				run_text[range] = "<#{tag}>#{text}</#{tag}>"
			end
		end
		
		return run_text
	end
	
end
