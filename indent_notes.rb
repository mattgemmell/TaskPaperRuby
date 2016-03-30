#!/usr/bin/ruby

=begin

This script visually indents all notes by one level, without affecting their children. This is useful for OmniFocus text exports, which put notes at the same level as the item they pertain to, whereas I prefer to have notes subordinate to their corresponding item.

=end

tp_ruby_dir = File.expand_path("~/Dropbox/TaskPaper/TaskPaperRuby/src")
file = File.expand_path("~/Desktop/test.taskpaper")

require_relative File.join(tp_ruby_dir, 'taskpaperdocument')

doc = TaskPaperDocument.new(file)

notes = doc.all_notes
notes.each do |note|
	# Make note a child of its previous sibling
	sibling = note.previous_sibling
	
	if sibling
		note.parent.remove_child(note)
		sibling.add_child(note)
		
		# Maintain note's children's apparent positions
		children = note.remove_all_children
		sibling.add_children(children)
	end
end

doc.save_file
