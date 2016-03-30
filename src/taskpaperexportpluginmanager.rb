#!/usr/bin/ruby

require_relative 'taskpaperexportplugin'
class TaskPaperExportPluginManager
	@@plugins = []
	@plugins_enabled = true
	
	class << self
		attr_reader :plugins
		attr_accessor :plugins_enabled
	end
	
	def self.add_plugin(plugin)
		if plugin.is_a?(TaskPaperExportPlugin)
			if !(@@plugins.include?(plugin))
				@@plugins.push(plugin)
			end
		end
	end
	
	def self.remove_plugin(plugin)
		if @@plugins.include?(plugin)
			@@plugins.delete(plugin)
		end
	end
	
	def self.process_text(item, run_text, output_type, before_conversion = true, options = {})
		output = run_text
		if TaskPaperExportPluginManager.plugins_enabled
			@@plugins.each do |plugin|
				output = plugin.process_text(item, run_text, output_type, before_conversion, options)
			end
		end
		return output
	end
	
	def self.process_link(item, run_text, output_type, before_conversion = true, options = {})
		output = run_text
		if TaskPaperExportPluginManager.plugins_enabled
			@@plugins.each do |plugin|
				output = plugin.process_link(item, run_text, output_type, before_conversion, options)
			end
		end
		return output
	end
	
	def self.process_tag_name(item, run_text, output_type, before_conversion = true, options = {})
		output = run_text
		if TaskPaperExportPluginManager.plugins_enabled
			@@plugins.each do |plugin|
				output = plugin.process_tag_name(item, run_text, output_type, before_conversion, options)
			end
		end
		return output
	end
	
	def self.process_tag_value(item, run_text, output_type, before_conversion = true, options = {})
		output = run_text
		if TaskPaperExportPluginManager.plugins_enabled
			@@plugins.each do |plugin|
				output = plugin.process_tag_value(item, run_text, output_type, before_conversion, options)
			end
		end
		return output
	end
end
