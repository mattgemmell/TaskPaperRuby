#!/usr/bin/ruby

# HTML export extensions

require_relative 'taskpaperdocument'
class TaskPaperDocument
	def to_html(only_type = nil, sidebar_mode = false)
		return (@root_item) ? @root_item.to_html(only_type, sidebar_mode) : ""
	end
	
	def to_sidebar
		return to_html(TaskPaperItem::TYPE_PROJECT, true)
	end
end

require_relative 'taskpaperitem'
class TaskPaperItem
	def to_html(only_type = nil, sidebar_mode = false)
		# HTML output, CSS-ready
		
		# If 'only_type' is specified, only that type of item will be output.
		# Types are found in TaskPaperItem: TYPE_TASK, etc.
		
		# If sidebar_mode is true, items will generate sidebar-suitable HTML instead.
		# This is only really of interest to projects (TYPE_PROJECT).

=begin
		The TaskPaperItem#to_html method takes account of any discrepancy in an item's nested depth in the graph and its actual indentation in the source file (via @extra_indent), generating an appropriate number of nested UL/LI tags so that the final HTML results accurately reflect the original indentation of each line (assuming suitable CSS is provided, e.g. to apply a margin-left to each UL).
=end
		
		# Output own content, then children
		output = ""
		if @type != TYPE_NULL
			@extra_indent.times do output += "<li class='extra-indent'><ul class='extra-indent'>" end
			
			if !sidebar_mode and (!only_type or @type == only_type)
				
				tag_data_attrs = ""
				@tags.each do |t|
					tag_data_attrs += " data-#{t[:name]}='#{t[:value]}'"
				end
				
				proj_id = (@type == TYPE_PROJECT) ? "id='#{id_attr}' " : ""
				empty_attr = (@content == "" and children.length == 0) ? " empty" : ""
				leaf_attr = (children.length == 0) ? " leaf" : ""
				
				output += "<li #{proj_id}class='#{type_name.downcase}' data-type='#{type_name.downcase}'#{tag_data_attrs} depth='#{effective_level + 1}'#{empty_attr}#{leaf_attr}>"
				
				posn = 0
			
				# Task prefix
				if @type == TYPE_TASK
					output += "<span class='task-prefix'><span class='task-marker'>#{content[0]}</span>"
					output += "#{@content[1]}</span>"
					posn += 2
				end
				
				# Metadata
				meta = metadata
				if meta.length == 0
					# Output whole line if there's no metadata
					run_text = @content[posn..-1]
					run_text = TaskPaperExportPluginManager.process_text(self, run_text, TaskPaperExportPlugin::OUTPUT_TYPE_HTML)
					output += "<span class='content' content>#{run_text}</span>"
					posn = @content.length
				else
					metadata.each_with_index do |m, i|
						# Output any content from last end-point up to start of this entry
						range_start = m[:range].begin
						range_end = m[:range].end
						if posn < range_start
							run_text = @content[posn..range_start - 1]
							run_text = TaskPaperExportPluginManager.process_text(self, run_text, TaskPaperExportPlugin::OUTPUT_TYPE_HTML)
							output += "<span class='content' content>#{run_text}</span>"
							posn = range_start;
						end
						
						# Output this entry, suitably wrapped
						if m[:type] == "tag"
							tagname = m[:name]
							tagval = m[:value]
							
							tagname_display = TaskPaperExportPluginManager.process_tag_name(self, tagname, TaskPaperExportPlugin::OUTPUT_TYPE_HTML)
							tagval_display = TaskPaperExportPluginManager.process_tag_value(self, tagval, TaskPaperExportPlugin::OUTPUT_TYPE_HTML, true, {"tagname" => tagname})
							
							# :name
							title_attr = (tagval != "") ? " title='#{tagval}'" : ""
							output += "<span class='tag' tag='data-#{tagname}' tagname='data-#{tagname}'#{title_attr} content>@#{tagname_display}</span>"
							if tagval and tagval != ""
								# (
								output += "<span class='tag' tag='data-#{tagname}' content>(</span>"
								
								# :value
								output += "<span class='tag' tag='data-#{tagname}' tagvalue='#{tagval}' content>#{tagval_display}</span>"
								
								# )
								output += "<span class='tag' tag='data-#{tagname}' content>)</span>"
							end
						
						elsif m[:type] == "link"
							link_text = TaskPaperExportPluginManager.process_link(self, m[:text], TaskPaperExportPlugin::OUTPUT_TYPE_HTML)
							output += "<span class='link' link='#{m[:text]}' content><a href='#{m[:url]}' target='_blank'>#{link_text}</a></span>"
						end
						posn = range_end
						
						# If this is the last entry, output any remaining content afterwards
						if i == meta.length - 1
							content_len = @content.length
							if posn < content_len
								run_text = @content[posn..-1]
								run_text = TaskPaperExportPluginManager.process_text(self, run_text, TaskPaperExportPlugin::OUTPUT_TYPE_HTML)
								output += "<span class='content' content>#{run_text}</span>"
								posn = range_start;
							end
							posn = content_len;
						end
					end
				end
			elsif sidebar_mode
				if only_type and only_type == TYPE_PROJECT and (@type == TYPE_PROJECT)
					output += "<li class='#{type_name.downcase}' data-type='#{type_name.downcase}'#{tag_data_attrs}><a href='##{id_attr}' title='#{title}'>#{title}</a>"
				else
					output += "<li class='extra-indent'>"
				end
			end
		end
		if @children and @children.length > 0 and @type != TYPE_NULL
			output += "#{TaskPaperItem.linebreak}<ul>#{TaskPaperItem.linebreak}"
		end
		@children.each do |child|
			output += child.to_html(only_type, sidebar_mode)
		end
		if @children and @children.length > 0 and @type != TYPE_NULL
			output += "#{TaskPaperItem.linebreak}</ul>#{TaskPaperItem.linebreak}"
		end
		if @type != TYPE_NULL
			output += "</li>#{TaskPaperItem.linebreak}"
			
			@extra_indent.times do output += "</ul></li>" end
		end
		if @type == TYPE_NULL
			if sidebar_mode
				output = "<ul class='taskpaper-root sidebar'><li class='extra-indent' data-type='project'><a href='#top' title='Home'>{{ tp-document-title }}</a><ul class='extra-indent'>#{output}</ul></li></ul>"
			else
				output = "<ul class='taskpaper-root'>#{output}</ul>"
			end
		end
		return output
	end
	
	def to_sidebar
		return to_html(TaskPaperItem::TYPE_PROJECT, true)
	end
end
