#!/usr/bin/ruby

class TaskPaperDocument
	require_relative 'taskpaperitem'
	
	attr_accessor :file_path
	
	def initialize(file_path = nil)
		@file_path = file_path
		
		@root_item = nil
		load_file
	end
	
	def load_file
		# Load TaskPaper file
		@root_item = TaskPaperItem.new(nil)
		raw_content = []
		
		if @file_path and @file_path != ""
			@file_path = File.expand_path(file_path)
		end
		if !@file_path or !File.exist?(@file_path)
			return
		end
		
		File.open(@file_path, 'r') do |this_file|
			while line = this_file.gets
				raw_content.push line
			end
		end
		
		# Create representation of the file's contents
		current_item = @root_item
		indentation_level = -1
		level = 0

		raw_content.each do |line|
			# Handle placement in graph, and hierarchical relationships.
=begin
	Note: We treat nested items as direct descendants regardless of difference in indentation level, which we consider to be a display matter. For example:
	
	Item1
	|-Item2
	|-----Item3
	|---Item4
	
	The above situation is uniquely possible in TaskPaper, unlike in strictly tree-based outliners like OmniOutliner or Scrivener etc, because in TaskPaper any line can be independently indented to any level. This script considers both Item3 and Item4 to be children of Item2 (and siblings of each other), regardless of the indentation difference. This seems logical, and reflects how TaskPaper's folding behaves.
	
	Each TaskPaperItem object has a #level method giving its nested depth in the graph, and also an @extra_indent instance variable to account for any discrepancy between its level and the actual tab-indentation of its line in the original document.
=end
			# Parse leading whitespace for level and @extra_indent
			content_start = TaskPaperItem.leading_indentation_length(line)
			if content_start > 0
				level = TaskPaperItem.leading_indentation_levels(line[0..content_start])
			else
				level = 0
			end
			
			new_item = TaskPaperItem.new(line[content_start..-1])
			
			indent_delta = level - indentation_level
			if indent_delta > 0
				# Add as child.
				current_item.add_child(new_item)
				#puts "Adding #{new_item.type_name} as child"
			elsif indent_delta < 0
				# Return back up tree to find suitable parent.
				# Note: As detailed above, parent may be at _any_ lesser indentation level.
				ancestor = current_item
				ancestry = 0
				while ancestor.level >= level and ancestor.parent != nil
					ancestor = ancestor.parent
					ancestry += 1
				end
				ancestor.add_child(new_item)
				#puts "Adding #{new_item.type_name} as child of ancestor #{ancestry}"
			else
				# Add as sibling (i.e. child of current parent).
				current_item.parent.add_child(new_item)
				#puts "Adding #{new_item.type_name} as sibling"
			end
			
			if indent_delta > 1
				new_item.extra_indent = (indent_delta - 1)
			end
			
			indentation_level = level
			current_item = new_item
		end
	end
	
	def save_file(path = @file_path)
		if path and path != ""
			File.open(File.expand_path(path), 'w') do |outfile|
				outfile.puts content
			end
		else
			puts "No path specified to save the file to."
		end
	end
	
	def items
		return (@root_item) ? @root_item.children : nil
	end
	
	def add_child(child)
		@root_item.add_child(child)
	end
	
	def content
		return to_text
	end
	
	def to_text
		return (@root_item) ? @root_item.to_text : ""
	end
	
	def to_tags
		return (@root_item) ? @root_item.to_tags : ""
	end
	
	def to_links
		return (@root_item) ? @root_item.to_links : ""
	end
	
	def to_structure
		return (@root_item) ? @root_item.to_structure : ""
	end
end
