#!/usr/bin/ruby

class TaskPaperTagIconsExportPlugin < TaskPaperExportPlugin

	@tags = {
				"flag"		=> {"replacement" => '&#9873;'},
				"priority"	=> {"values" => {"high" => "‼️", "1" => "‼️"}},
				"done"		=> {"replacement" => '✔'},
				"search"	=> {"replacement" => '🔍'}
			}
	
	class << self
		attr_accessor :tags
	end
	
	def process_tag_name(item, run_text, output_type, before_conversion = true, options = {})
		if output_type == OUTPUT_TYPE_HTML
			return tag_icon(run_text)
		end
		
		return run_text
	end
	
	def process_tag_value(item, run_text, output_type, before_conversion = true, options = {})
		if output_type == OUTPUT_TYPE_HTML
			return tag_icon(options["tagname"], run_text)
		end
		
		return run_text
	end
	
	def tag_icon(tagname, tagval = nil)
		wants_value = (tagval != nil)
		result = (wants_value) ? tagval : tagname
		if TaskPaperTagIconsExportPlugin.tags.include?(tagname)
			tag_info = TaskPaperTagIconsExportPlugin.tags[tagname]
			if wants_value
				# Tag value
				if tag_info.include?("values")
					vals = tag_info["values"]
					if vals.include?(tagval)
						return "<span class='tag-icon tag-value #{tagval}' title='#{tagval}'>#{vals[tagval]}</span>"
					end
				end
			else
				# Tag name
				if tag_info.include?("replacement")
					return "<span class='tag-icon #{tagname}' title='#{tagname}'>#{tag_info["replacement"]}</span>"
				end
			end
		end
		
		return result
	end
	
end
