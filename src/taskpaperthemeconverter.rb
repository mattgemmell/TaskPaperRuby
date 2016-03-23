#!/usr/bin/ruby

class TaskPaperThemeConverter

=begin
	Requires Less CSS: http://lesscss.org
	If you're on a Mac, the easiest way to get Less is:
	
	1. Install Homebrew: (instructions at http://brew.sh ).
	2. Use Homebrew to install npm: "brew install npm" in Terminal.
	3. Use npm to install Less: "npm install -g less" in Terminal.
	
	Now you can use Less via "lessc" in Terminal.
=end
	
	def initialize(output_file_path)
		@base_theme_path = "/Applications/TaskPaper.app/Contents/Resources/base.less"
		@user_theme_path = "~/Library/Application Support/TaskPaper/theme.less"
		@css_tweaks_path = File.dirname(__FILE__)+"/css/tweaks.css"
		@css_fallback_path = File.dirname(__FILE__)+"/css/fallback.css"
		@output_file_path = output_file_path
		
		convert_theme
	end
	
	def file_contents(path, expand=true)
		contents = ""
		if expand
			path = File.expand_path(path)
		end
		if File.exists?(path)
			File.open(path, 'r') do |the_file|
				while line = the_file.gets
					contents += line;
				end
			end
		else
			puts "Couldn't find file: #{path}"
		end
		return contents
	end
	
	def write_file(contents, path)
		File.open(File.expand_path(path), 'w') do |outfile|
			outfile.puts contents
		end
	end
	
	def less_installed?
		result = `which lessc`
		return (result != "")
	end
	
	def less_convert(content)
		result = ""
		tmp_file = "/tmp/taskpaperthemeconvertertemp.txt"
		write_file(content, tmp_file)
		`lessc #{tmp_file} #{tmp_file}`
		result = file_contents(tmp_file, false)
		File.delete(tmp_file)
		
		return result
	end
	
	def convert_theme
		# Load TaskPaper theme files and CSS tweaks
		if less_installed?
			raw_content = ""
			raw_content += file_contents(@base_theme_path) + "\n"
			raw_content += file_contents(@user_theme_path) + "\n"
			raw_content += file_contents(@css_tweaks_path, false)
			
			# Make some modifications
			css_selector_regexp = /([a-zA-Z\-]+)\s*:\s*([^;]+)\s*;/i
			raw_content.gsub!(/\beditor\b/i, 'body')
			raw_content.gsub!(/\b(?<!-)item(?!-)\b/i, 'li')
			raw_content.gsub!(/\brun\b/i, 'span')
			raw_content.gsub!("$USER_FONT_SIZE", "@base-font-size")
			
			# Deal with LineStyles
			linestyle_selector_regexp = /([a-zA-Z\-]+)\s*:\s*(NSUnderline[a-zA-Z]+\s*)+\s*;/i
			linestyle_matches = raw_content.to_enum(:scan, linestyle_selector_regexp).map { Regexp.last_match }
			linestyle_matches.reverse.each do |match|
				selector = match[1].downcase
				value = match[2]
				range = Range.new(match.begin(0), match.end(0), true)
				new_value = nil
				if selector == "text-strikethrough" or selector == "text-underline"
					if /NSUnderlineStyle(Single|Thick)/i =~ value
						new_value = (selector == "text-strikethrough") ? "line-through" : "underline"
					elsif /NSUnderlineStyleNone/i =~ value
						new_value = "none"
					end
					if new_value
						raw_content[range] = "text-decoration: #{new_value};"
					end
				end
			end
			
			# Convert with Less
			css_content = less_convert(raw_content)			
		else
			puts "You don't have Less CSS installed, so I couldn't convert your theme."
			puts "See this project's README file for how to install Less CSS."
			css_content = file_contents(@css_fallback_path, false)
		end
		
		# Write output file
		write_file(css_content, @output_file_path)
	end
end
