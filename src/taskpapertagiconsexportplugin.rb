#!/usr/bin/ruby

class TaskPaperTagIconsExportPlugin < TaskPaperExportPlugin

	@@tags = {
				"flag"		=> {"replacement" => '🚩'},
				"priority"	=> {"replacement" => '💥', 
								"values" => {"high" => "‼️", "1" => "‼️"}},
				"done"		=> {"replacement" => '✅'}
			}
	
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
		if @@tags.include?(tagname)
			tag_info = @@tags[tagname]
			if wants_value
				if tag_info.include?("values")
					vals = tag_info["values"]
					if vals.include?(tagval)
						return vals[tagval]
					end
				end
			else
				if tag_info.include?("replacement")
					return tag_info["replacement"]
				end
			end
		end
		
		return result
	end
	
end
