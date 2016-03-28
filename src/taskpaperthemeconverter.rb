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
		#@base_theme_path = "/Applications/TaskPaper Preview.app/Contents/Resources/base.less"
		#@user_theme_path = "/Applications/TaskPaper Preview.app/Contents/Resources/template.user.less"
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
			user_theme_offset = raw_content.length
			raw_content += file_contents(@user_theme_path) + "\n"
			tweaks_offset = raw_content.length
			raw_content += file_contents(@css_tweaks_path, false)
			
			# Make some modifications
			#css_selector_regexp = /([a-zA-Z\-]+)\s*:\s*([^;]+)\s*;/i
			
			# Handle colour-overriding due to (correct) LI>UL HTML nesting,
			# and reflect default link styling in TaskPaper
			task_color_override = <<END

item[data-type=task], item[data-type=note] {
	color: @text-color;
}

run[link] a {
	text-underline: NSUnderlineStyleNone;
}

END
			raw_content = raw_content.insert(user_theme_offset, task_color_override)
			
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
			
			# Quote numeric attribute-values, so it doesn't mess up CSS rendering
			num_attr_val_regexp = /\[[^=\]]+=(\d+)\]/i
			num_attr_matches = raw_content.to_enum(:scan, num_attr_val_regexp).map { Regexp.last_match }
			num_attr_matches.reverse.each do |match|
				num_val = match[1]
				range = Range.new(match.begin(1), match.end(1), true)
				raw_content[range] = "\"#{num_val}\""
			end
			
			# Quote font-family attributes
			font_attr_regexp = /@?font-family\s*:\s*([^;]+);/i
			font_attr_matches = raw_content.to_enum(:scan, font_attr_regexp).map { Regexp.last_match }
			font_attr_matches.reverse.each do |match|
				font_str = match[1]
				range = Range.new(match.begin(1), match.end(1), true)
				# Might have multiple fonts (comma-separated)
				# For each, check it's not a @variable, and isn't already quoted (' or ")
				fonts = font_str.split(',')
				modified_fonts = []
				fonts.each do |font|
					font.strip!
					if (/^['"].+?['"]$/i =~ font) == nil and font[0] != "@"
						font = "\"#{font}\""
					end
					modified_fonts.push(font)
				end
				quoted_font_str = modified_fonts.join(", ")
				# Special patch for the default app font
				if /^["']Source Sans/ =~ quoted_font_str
					quoted_font_str += ", Helvetica, Verdana, sans-serif"
				end
				
				raw_content[range] = quoted_font_str
			end
			
			# Paragraph spacing
			raw_content.gsub!(/paragraph-spacing-before\s*:\s*(\d+);/i, 'margin-top: \1px;')
			raw_content.gsub!(/paragraph-spacing-after\s*:\s*(\d+);/i, 'margin-bottom: \1px;')
			
			# Link colours
			link_color_regexp = /(?-m)^[^\]\}]*?\[link\](?m)\s*?\{[^\{]*?(?-m)color\s*?:\s*?([^;\}]+?);/i
			link_color = "blue"
			link_color_matches = raw_content.to_enum(:scan, link_color_regexp).map { Regexp.last_match }
			if link_color_matches and link_color_matches.length > 0
				link_color = link_color_matches[-1][1].strip
			end
			raw_content.gsub!("$LINK_COLOR", link_color) # in tweaks CSS file
			
			# Selection background colour
			sel_bg_regexp = /(?<!@)selection-background-color\s*:\s*([^;]+)\s*;/i
			sel_bg_matches = raw_content.to_enum(:scan, sel_bg_regexp).map { Regexp.last_match }
			if sel_bg_matches and sel_bg_matches.length > 0
				sel_bg_color = sel_bg_matches[-1][1].strip
				raw_content += "\n::selection { background: #{sel_bg_color}; }\n"
			end
			
			# Handle-colour (for future versions of browsers)
			handle_color_regexp = /(?<!@)handle-color\s*:\s*([^;]+)\s*;/i
			handle_color = "inherit"
			handle_color_matches = raw_content.to_enum(:scan, handle_color_regexp).map { Regexp.last_match }
			if handle_color_matches and handle_color_matches.length > 0
				handle_color = handle_color_matches[-1][1].strip
			end
			raw_content.gsub!("$HANDLE_COLOR", handle_color) # in tweaks CSS file
			
			# Item indent
			item_indent_regexp = /(?<!@)item-indent\s*:\s*([^;]+)\s*;/i
			item_indent = "30"
			item_indent_matches = raw_content.to_enum(:scan, item_indent_regexp).map { Regexp.last_match }
			if item_indent_matches and item_indent_matches.length > 0
				item_indent = item_indent_matches[-1][1].strip
			end
			raw_content.gsub!("$ITEM_INDENT", item_indent) # in tweaks CSS file
			
			# Line height
			raw_content.gsub!("line-height-multiple", "line-height")
			
			# Strip inapplicable/incompatible selectors
			strip_selectors = [
								"search-item-prefix",
								"caret-width",
								"caret-color",
								"invisibles-color",
								"drop-indicator-color",
								"guide-line-color",
								"guide-line-width",
								"message-color",
								"item-indent", # handled above
								"folded-items-label",
								"filtered-items-label",
								"item-handle-size",
								"handle-color", # handled above
								"selection-background-color", # handled above
								"text-underline-color",
								"text-strikethrough-color",
								"text-expansion",
								"text-baseline-offset",
							  ]
			strip_selectors.each do |sel|
				raw_content.gsub!(/((?<!@)#{sel})\s*:\s*([^;]+)\s*;/i, '')
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
