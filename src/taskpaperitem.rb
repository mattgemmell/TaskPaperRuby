#!/usr/bin/ruby

require_relative 'taskpaperexportpluginmanager'
class TaskPaperItem
	TYPE_ANY = 0
	TYPE_NULL = 1
	TYPE_TASK = 2
	TYPE_PROJECT = 3
	TYPE_NOTE = 4
	
	LINEBREAK_UNIX = "\n" # Unix, Linux, and Mac OS X
	LINEBREAK_MAC = "\r" # classic Mac OS 9 and older
	LINEBREAK_WINDOWS = "\r\n" # DOS and Windows
	
	@linebreak = LINEBREAK_UNIX
	@tab_size = 4 # Number of spaces used per indentation level (if tabs aren't used)
	@convert_atx_headings = false # ie. Markdown "## Headings" to "Projects:"
	
	class << self
		attr_accessor :linebreak, :tab_size, :convert_atx_headings
	end
	
	# If you want to inspect and debug these, may I suggest https://regex101.com ?
	@@tab_regexp = /^(?:\t|\ {#{TaskPaperItem.tab_size}})+/io
	@@project_regexp = /^(?>\s*)(?>[^-].*?:)(\s*@\S+)*\s*$/i
	@@atx_headings_regexp = /^(\s*?)\#+\s*([^:]+?)$/i
	@@tag_regexp = /\B@((?>[a-zA-Z0-9\.\-_]+))(?:\((.*?(?<!\\))\))?/i
	@@tags_rstrip_regexp = /(\s*\@[^\.\s\(\)\\]+(\(.+?(?<!\\)\))?){1,}$/i
	@@uri_regexp = /([a-zA-Z0-9\-_\+\.]+:(?:\/\/)?(?:[a-zA-Z0-9\-_\.\+]+)(?::[a-zA-Z0-9\-_\.\+]+)*@?(?:[a-zA-Z0-9\-]+\.){1,}[a-zA-Z]{2,}(?::\d+)?(?:[\/\?]\S*)?)/i
	@@email_regexp = /([a-zA-Z0-9\-\_\+\.]+\@\S+\.\S+)/i
	@@domain_regexp = /((?<!@)\b(?:[a-zA-Z0-9\-]+\.){1,}[a-zA-Z]{2,}(?::\d+)?(?:[\/\?]\S*)?)/i
	@@link_regexp = /#{@@uri_regexp}|#{@@email_regexp}|#{@@domain_regexp}/io
	
	attr_reader :children, :type, :tags, :links
	attr_accessor :parent, :content, :extra_indent
	
	def self.leading_indentation_length(line)
		# Returns character-length of leading tab/space indentation in line
		indent_len = 0
		match = @@tab_regexp.match(line)
		if match
			indent_len = match[0].length
		end
		return indent_len
	end
	
	def self.leading_indentation_levels(line)
		# Returns number of leading tab/space indentation levels in WHITESPACE-ONLY line
		num_tab_indents = line.scan(/\t/).length
		num_space_indents = line.scan(/\ {#{TaskPaperItem.tab_size}}/o).length
		return num_tab_indents + num_space_indents
	end

	def initialize(content)
		Encoding.default_external = "utf-8"
		
		# Instance variables
		if content
			@content = content.gsub(/[\r\n]+/, '') # full text of item, without linebreak
		end
		
		@type = TYPE_NULL
		@tags = [] # of {'name', 'value', 'range', 'type':"tag"} tags
		@links = [] # of {'text', 'url', 'range', 'type':"link"} links; range is within self.content
		@children = []
		@parent = nil
		@extra_indent = 0
		
		if @content
			parse
		end
	end
	
	def parse # private method
		# Parse @content to populate our instance variables
		
		# Leading indentation
		content_start = TaskPaperItem.leading_indentation_length(@content)
		if content_start > 0
			@extra_indent += TaskPaperItem.leading_indentation_levels(@content[0..content_start])
			@content = @content[content_start, @content.length]
		end
		
		# Markdown-style ATX headings conversion
		if TaskPaperItem.convert_atx_headings
			heading_match = @@atx_headings_regexp.match(@content)
			if heading_match
				@content.gsub!(heading_match[0], "#{heading_match[1]}#{heading_match[2]}:")
			end
		end
		
		# Type of item
		if @content.start_with?("- ", "* ")
			@type = TYPE_TASK
		elsif @@project_regexp =~ @content
			@type = TYPE_PROJECT
		else
			@type = TYPE_NOTE
		end
		
		# Tags
		@tags = []
		tag_matches = @content.to_enum(:scan, @@tag_regexp).map { Regexp.last_match }
		tag_matches.each do |match|
			name = match[1]
			value = ""
			if match[2]
				value = match[2]
			end
			range = Range.new(match.begin(0), match.end(0), true)
			@tags.push({name: name, value: value, range: range, type: "tag"})
		end
		
		# Links
		@links = []
		link_matches = @content.to_enum(:scan, @@link_regexp).map { Regexp.last_match }
		link_matches.each do |match|
			text = match[0]
			if match[1] != nil #uri
				url = text
			elsif match[2] != nil # email
				url = "mailto:#{text}"
			else # domain
				url = "http://#{text}"
			end
			range = Range.new(match.begin(0), match.end(0), true)
			@links.push({text: text, url: url, range: range, type: "link"})
		end
	end
	private :parse
	
	def content=(value)
		@content = (value) ? value : ""
		parse
	end
	
	def level
		# Depth in hierarchy, regardless of extra indentation
		if @type == TYPE_NULL and !@parent
			return -1
		end
		
		level = 0
		ancestor = @parent
		while ancestor != nil and not (ancestor.type == TYPE_NULL and ancestor.parent == nil)
			level += 1
			ancestor = ancestor.parent
		end
		
		return level
	end
	
	def effective_level
		# Actual (visual) indentation level
		if !@parent and @type != TYPE_NULL
			return @extra_indent
		end
		
		parent_indent = -2 # nominal parent of root (-1) item
		if @parent
			parent_indent = @parent.effective_level
		end
		return parent_indent + 1 + @extra_indent
	end
	
	def project
		# Returns closest ancestor project
		project = nil
		ancestor = @parent
		while ancestor and ancestor.type != TYPE_NULL
			if ancestor.type == TYPE_PROJECT
				project = ancestor
				break
			else
				ancestor = ancestor.parent
			end
		end
		return project
	end
	
	def children_flat(only_type = TaskPaperItem::TYPE_ANY, pre_order = true)
		# Recursively return a flat array of items, optionally filtered by type
		# (This is a depth-first traversal; set pre_order to false for post-order)
		
		result = []
		@children.each do |child|
			result = result.concat(child.children_flat(only_type, pre_order))
		end
		
		if @type != TYPE_NULL and only_type and (only_type == TYPE_ANY or only_type == @type)
			if pre_order
				result = result.unshift(self)
			else
				result = result.push(self)
			end
		end
		
		return result
	end
	
	def add_child(child)
		return insert_child(child, -1)
	end
	
	def insert_child(child, index)
		if index <= @children.length
			if child.is_a?(String)
				child = TaskPaperItem.new(child)
			end
			@children.insert(index, child) # /facepalm
			child.parent = self
			return child
		end
		return nil
	end
	
	def add_children(children)
		result = []
		children.each do |child|
			result.push(insert_child(child, -1))
		end
		return result
	end
	
	def remove_child(index)
		if index.is_a?(TaskPaperItem)
			if @children.include?(index)
				index = @children.index(index)
			else
				return index
			end
		end
		if index < @children.length
			child = @children[index]
			child.parent = nil
			@children.delete_at(index)
			return child
		end
	end
	
	def remove_children(range)
		if range.is_a?(Integer)
			range = range..range
		end
		removed = []
		(range.last).downto(range.first) { |index|
			if index < @children.length
				child = @children[index]
				removed.push(child)
				child.parent = nil
				@children.delete_at(index)
			end
		}
		return removed
	end
	
	def remove_all_children
		return remove_children(0..(@children.length - 1))
	end
	
	def previous_sibling
		sibling = nil
		if @parent and @parent.type != TYPE_NULL
			siblings = @parent.children
			if siblings.length > 1
				my_index = siblings.index(self)
				if my_index > 0
					return siblings[my_index - 1]
				end
			end
		end
		return sibling
	end
	
	def next_sibling
		sibling = nil
		if @parent and @parent.type != TYPE_NULL
			siblings = @parent.children
			if siblings.length > 1
				my_index = siblings.index(self)
				if my_index < siblings.length - 1
					return siblings[my_index + 1]
				end
			end
		end
		return sibling
	end
	
	def title
		if @type == TYPE_PROJECT
			return @content[0..@content.rindex(':') - 1]
		elsif @type == TYPE_TASK
			return @content[2..-1].gsub(@@tags_rstrip_regexp, '')
		else
			return @content
		end
	end
	
	def md5_hash
		require 'digest/md5'
		return Digest::MD5.hexdigest(@content)
	end
	
	def id_attr
		id = title
		
		metadata.each do |x|
			if x[:type] == "tag"
				val_str = (x[:value] != "") ? "(#{x[:value]})" : ""
				id = id.gsub("#{x[:name]}#{val_str}", '')
			elsif x[:type] == "link"
				id = id.gsub("#{x[:text]}", '')
			end
		end
		
		id = id.strip.downcase.gsub(/(&|&amp;)/, ' and ').gsub(/[\s\.\/\\]/, '-').gsub(/[^\w-]/, '').gsub(/[-_]{2,}/, '-').gsub(/^[-_]/, '').gsub(/[-_]$/, '')
		
		if id == ""
			# No content left after stripping tags, links, and special characters.
			# We'll use an MD5 hash of the full line.
			id = md5_hash
		end
		
		return id
	end
	
	def metadata
		# Return unified array of tags and links, ordered by position in line
		metadata = @tags + @links
		return metadata.sort_by { |e| e[:range].begin }
	end
	
	def type_name
		if @type == TYPE_PROJECT
			return "Project"
		elsif  @type == TYPE_TASK
			return "Task"
		elsif  @type == TYPE_NOTE
			return "Note"
		else
			return "Null"
		end
	end
	
	def to_s
		return @content
	end
	
	def inspect
		output = "[#{(self.effective_level)}] #{self.type_name}: #{self.title}"
		if @tags.length > 0
			output += " tags: #{@tags}"
		end
		if @links.length > 0
			output += " links: #{@links}"
		end
		if @children.length > 0
			output += " [#{@children.length} child#{(@children.length == 1) ? "" : "ren"}]"
		end
		if self.done?
			output += " [DONE]"
		end
		return output
	end
	
	def change_to(new_type)
		# Takes a type constant, e.g. TYPE_TASK etc.
		if (@type != TYPE_NULL and @type != TYPE_ANY and
			new_type != TYPE_NULL and new_type != TYPE_ANY and 
			@type != new_type)
			
			# Use note as our base type
			if @type == TYPE_TASK
				# Strip task prefix
				@content = @content[2..-1]
				
			elsif @type == TYPE_PROJECT
				# Strip rightmost colon
				rightmost_colon_index = @content.rindex(":")
				if rightmost_colon_index != nil
					@content[rightmost_colon_index, 1] = ""
				end
			end
			
			if new_type == TYPE_TASK
				# Add task prefix
				@content = "- #{@content}"
				
			elsif new_type == TYPE_PROJECT
				# Add colon
				insertion_index = -1
				match = @content.match(@@tags_rstrip_regexp)
				if match
					insertion_index = match.begin(0)
				else
					last_non_whitespace_char_index = @content.rindex(/\S/i)
					if last_non_whitespace_char_index != nil
						insertion_index = last_non_whitespace_char_index + 1
					end
				end
				@content[insertion_index, 0] = ":"
			end 
			
			parse
		end
	end
	
	def tag_value(name)
		# Returns value of tag 'name', or empty string if either the tag exists but has no value, or the tag doesn't exist at all.
		
		value = ""
		tag = @tags.find {|x| x[:name].downcase == name}
		if tag
			value = tag[:value]
		end
		
		return value
	end
	
	def has_tag?(name)
	 	return (@tags.find {|x| x[:name].downcase == name} != nil)
	end
	
	def done?
		return has_tag?("done")
	end
	
	def is_done?
		return done?
	end
	
	def set_done(val = true)
		is_done = done?
		if val == true and !is_done
			set_tag("done")
		elsif val == false and is_done
			remove_tag("done")
		end
	end
	
	def toggle_done
		set_done(!(done?))
	end
	
	def tag_string(name, value = "")
		val = (value != "") ? "(#{value})" : ""
		return "@#{name}#{val}"
	end
	
	def set_tag(name, value = "", force_new = false)
		# If tag doesn't already exist, add it at the end of content.
		# If tag does exist, replace its range with new form of the tag via tag_string.
		value = (value != nil) ? value : ""
		new_tag = tag_string(name, value)
		if has_tag?(name) and !force_new
			tag = @tags.find {|x| x[:name].downcase == name}
			@content[tag[:range]] = new_tag
		else
			@content += " #{new_tag}"
		end
		parse
	end
	
	def add_tag(name, value = "", force_new = true)
		# This method, unlike set_tag_, defaults to adding a new tag even if a tag of the same name already exists.
		set_tag(name, value, force_new)
	end
	
	def remove_tag(name)
		if has_tag?(name)
			# Use range(s), in reverse order.
			@tags.reverse.each do |tag|
				if tag[:name] == name
					strip_tag(tag)
				end
			end
			parse
		end
	end
	
	def remove_all_tags
		@tags.reverse.each do |tag|
			strip_tag(tag)
		end
		parse
	end
	
	def strip_tag(tag) # private method
		# Takes a tag hash, and removes the tag from @content
		# Does not perform a #parse, but we should do so afterwards.
		# If calling multiple times before a #parse, do so in reverse order in @content.
		
		range = tag[:range]
		whitespace_regexp = /\s/i
		content_len = @content.length
		tag_start = range.begin
		tag_end = range.end
		whitespace_before = (tag_start > 0 and (whitespace_regexp =~ @content[tag_start - 1]) != nil)
		whitespace_after = (tag_end < content_len - 1 and (whitespace_regexp =~ @content[tag_end]) != nil)
		if whitespace_before and whitespace_after
			# If tag has whitespace before and after, also remove the whitespace before.
			range = Range.new(tag_start - 1, tag_end, true)
		elsif tag_start == 0 and whitespace_after
			# If tag is at start of line and has whitespace after, also remove the whitespace after.
			range = Range.new(tag_start, tag_end + 1, true)
		elsif tag_end == content_len - 1 and whitespace_before
			# If tag is at end of line and has whitespace before, also remove the whitespace before.
			range = Range.new(tag_start - 1, tag_end, true)
		end
		@content[range] = ""
	end
	private :strip_tag
	
	def total_tag_values(tag_name, always_update = false)
		# Returns recursive total of numerical values of the given tag.
		# If tag is present, its value will be updated according to recursive total of its descendants. If always_update is true, tag value will be set even if it wasn't present.
		# Leaf elements without the relevant tag are counted as zero.
		# Tag values on branch elements are ignored, and overwritten with their descendants' recursive total.
		total = 0
		if tag_name and tag_name != ""
			has_tag = has_tag?(tag_name)
			if @type != TYPE_NULL and @children.length == 0
				if has_tag
					val_match = /\d+/i.match(tag_value(tag_name))
					if val_match
						val = val_match[0].to_i
						total += val
					end
				end
			end
			
			@children.each do |child|
				total += child.total_tag_values(tag_name, always_update)
			end
			
			if @type != TYPE_NULL
				if has_tag or always_update
					set_tag(tag_name, total)
				end
			end
		end
		
		return total
	end

	def to_structure(include_titles = true)
		# Indented text output with items labelled by type, and project/task decoration stripped
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			suffix = (include_titles) ? " #{title}" : ""
			output += "#{"\t" * (self.effective_level)}[#{type_name}]#{suffix}#{TaskPaperItem.linebreak}"
		end
		@children.each do |child|
			output += child.to_structure(include_titles)
		end
		return output
	end
	
	def to_tags(include_values = true)
		# Indented text output with just item types, tags, and values
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			output += "#{"\t" * (self.effective_level)}[#{type_name}] "
			if @tags.length > 0
				@tags.each_with_index do |tag, index|
					output += "@#{tag[:name]}"
					if include_values and tag[:value].length > 0
						output += "(#{tag[:value]})"
					end
					if index < @tags.length - 1
						output += ", "
					end
				end
			else
				output += "(none)"
			end
			output += "#{TaskPaperItem.linebreak}"
		end
		@children.each do |child|
			output += child.to_tags(include_values)
		end
		return output
	end
	
	def all_tags(with_values = true, prefixed = false)
		# Text output with just item tags
		
		# Output own content, then children
		output = []
		if @type != TYPE_NULL
			if @tags.length > 0
				prefix = (prefixed) ? "@" : ""
				@tags.each do |tag|
					tag_value = ""
					if (with_values)
						tag_val = tag_value(tag[:name])
					end
					value_suffix = (with_values and tag_val != "") ? "(#{tag_val})" : ""
					output.push("#{prefix}#{tag[:name]}#{value_suffix}")
				end
			end
		end
		@children.each do |child|
			output += child.all_tags(with_values, prefixed)
		end
		return output
	end
	
	def to_links(add_missing_protocols = true)
		# Text output with just item links
		
		# Bare domains (domain.com) or email addresses (you@domain.com) are included; the add_missing_protocols parameter will prepend "http://" or "mailto:" as appropriate.
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			if @links.length > 0
				key = (add_missing_protocols) ? :url : :text
				@links.each do |link|
					output += "#{link[key]}#{TaskPaperItem.linebreak}"
				end
			end
		end
		@children.each do |child|
			output += child.to_links(add_missing_protocols)
		end
		return output
	end
	
	def to_text
		# Indented text output of original content, with normalised (tab) indentation
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			converted_content = TaskPaperExportPluginManager.process_text(self, @content, TaskPaperExportPlugin::OUTPUT_TYPE_TEXT)
			output += "#{"\t" * (self.effective_level)}#{converted_content}#{TaskPaperItem.linebreak}"
		end
		@children.each do |child|
			output += child.to_text
		end
		return output
	end
	
	def to_json
		# Hierarchical output of content as JSON: http://json.org
		
		output = ""
		if @type != TYPE_NULL
			converted_content = TaskPaperExportPluginManager.process_text(self, @content, TaskPaperExportPlugin::OUTPUT_TYPE_JSON)
			converted_content = json_escape(converted_content)
			output += "{"
			output += "\"content\": \"#{converted_content}\",#{TaskPaperItem.linebreak}"
			output += "\"title\": \"#{json_escape(title)}\",#{TaskPaperItem.linebreak}"
			output += "\"type\": \"#{@type}\",#{TaskPaperItem.linebreak}"
			output += "\"type_name\": \"#{type_name}\",#{TaskPaperItem.linebreak}"
			
			output += "\"id_attr\": \"#{json_escape(id_attr)}\",#{TaskPaperItem.linebreak}"
			output += "\"md5_hash\": \"#{json_escape(md5_hash)}\",#{TaskPaperItem.linebreak}"
			
			output += "\"level\": #{level},#{TaskPaperItem.linebreak}"
			output += "\"effective_level\": #{effective_level},#{TaskPaperItem.linebreak}"
			output += "\"extra_indent\": #{@extra_indent},#{TaskPaperItem.linebreak}"
			
			output += "\"done\": #{done?},#{TaskPaperItem.linebreak}"
			
			output += "\"tags\": ["
			@tags.each_with_index do |x, index|
				output += "{"
				output += "\"type\": \"#{x[:type]}\","
				output += "\"name\": \"#{json_escape(x[:name])}\","
				output += "\"value\": \"#{json_escape(x[:value])}\","
				output += "\"begin\": #{x[:range].begin},"
				output += "\"end\": #{x[:range].end}"
				output += "}"
				if index < @tags.length - 1
					output += ", "
				end
			end
			output += "],#{TaskPaperItem.linebreak}"
			
			output += "\"links\": ["
			@links.each_with_index do |x, index|
				output += "{"
				output += "\"type\": \"#{x[:type]}\","
				output += "\"text\": \"#{json_escape(x[:text])}\","
				output += "\"url\": \"#{json_escape(x[:url])}\","
				output += "\"begin\": #{x[:range].begin},"
				output += "\"end\": #{x[:range].end}"
				output += "}"
				if index < @links.length - 1
					output += ", "
				end
			end
			output += "],#{TaskPaperItem.linebreak}"
			
			output += "\"children\": "
		end
		output += "["
		@children.each_with_index do |child, index|
			output += child.to_json
			if index < @children.length - 1
				output += ", "
			end
		end
		output += "]"
		if @type != TYPE_NULL
			output += "}"
		end
		return output
	end
	
	def json_escape(str)
		result = str.gsub(/\\/i, "\\\\\\").gsub(/(?<!\\)\"/i, "\\\"")
		return result
	end
	private :json_escape
end
