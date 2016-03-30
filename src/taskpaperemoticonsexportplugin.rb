#!/usr/bin/ruby

class TaskPaperEmoticonsExportPlugin < TaskPaperExportPlugin

	@emoticons = [
					{pattern: /:\-?\)/, replacement: '😃', class_name: 'smile'},
					{pattern: /:\-?\(/, replacement: '🙁', class_name: 'sadface'},
					{pattern: /;\-?\)/, replacement: '😉', class_name: 'wink'},
					{pattern: /:\-?\//, replacement: '😕', class_name: 'confused'},
				]
	
	class << self
		attr_accessor :emoticons
	end
	
	def process_text(item, run_text, output_type, before_conversion = true, options = {})
		if output_type == OUTPUT_TYPE_HTML
			
			TaskPaperEmoticonsExportPlugin.emoticons.each do |emoticon|
				matches = run_text.to_enum(:scan, emoticon[:pattern]).map { Regexp.last_match }
				matches.reverse.each do |match|
					text = match[0]
					range = Range.new(match.begin(0), match.end(0), true)
					run_text[range] = "<span class='emoticon #{emoticon[:class_name]}' title='#{emoticon[:class_name]}'>#{emoticon[:replacement]}</span>"
				end
			end
			
		end
		
		return run_text
	end
	
end
