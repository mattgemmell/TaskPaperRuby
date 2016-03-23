#!/usr/bin/ruby

# TaskPaperRuby
#version = "1.0.0" # 2016-03-23
#
# This script converts TaskPaper files to HTML.
# Output is via a template file.
#
# Made by Matt Gemmell - mattgemmell.com - @mattgemmell
#
github_url = "http://github.com/mattgemmell/TaskPaperRuby"
#
# Requirements: [optional/recommended] Less CSS. See README.


# Configuration ============================================
html_template_file_path = File.dirname(__FILE__)+"/template.html"
css_output_filename = "taskpaper-styles.css"
# ==========================================================


require_relative 'src/taskpaperdocument'
require_relative 'src/taskpaper+html'
require_relative 'src/taskpaperthemeconverter'


# Handle command line arguments
if ARGV.count < 2
	puts "Usage: ruby taskpaper-to-html.rb INPUT_FILE_PATH OUTPUT_FILE_PATH [TEMPLATE_PATH]"
	puts "(Input file should be a TaskPaper file. Output will be HTML.)"
	exit
elsif ARGV.count > 2
	html_template_file_path = ARGV[2]
end

input_file_path = File.expand_path(ARGV[0])
html_output_file_path = File.expand_path(ARGV[1])
html_template_file_path = File.expand_path(html_template_file_path)
css_output_file_path = File.join(File.dirname(html_output_file_path), css_output_filename)

# Ensure we have an input file to work with
if !File.exist?(input_file_path)
	puts "Couldn't find input file \"#{input_file_path}\". ¯\\_(ツ)_/¯"
	exit
end

# Ensure we have a template file to work with
if !File.exist?(html_template_file_path)
	puts "Couldn't find input file \"#{html_template_file_path}\". ¯\\_(ツ)_/¯"
	exit
end

# Load TaskPaper file
document = TaskPaperDocument.new(input_file_path)

# Produce HTML output from document
document_html = document.to_html
sidebar_html = document.to_sidebar

# Load HTML template
template_contents = ""
File.open(html_template_file_path, 'r') do |the_file|
	while line = the_file.gets
		template_contents += line;
	end
end

# Insert data into template
template_vars = {
				# All vars are prefixed with "tp-" in the template file.
				"document-title" => File.basename(input_file_path, ".*"),
				"css-output-filename" => css_output_filename,
				"sidebar-html" => sidebar_html,
				"document-html" => document_html
				}

template_variable_regexp = /\{\{\s*tp-(\S+)\s*\}\}/i
var_matches = template_contents.to_enum(:scan, template_variable_regexp).map { Regexp.last_match }
var_matches.reverse.each do |match|
	token = match[1]
	range = Range.new(match.begin(0), match.end(0), true)
	template_contents[range] = template_vars[token]
end

# Write HTML file
File.open(html_output_file_path, 'w') do |outfile|
  outfile.puts template_contents
end

# Write CSS file
TaskPaperThemeConverter.new(css_output_file_path)
