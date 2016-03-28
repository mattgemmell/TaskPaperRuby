#!/usr/bin/ruby

require_relative 'src/taskpaperdocument'

# Make a new document and add a project
doc = TaskPaperDocument.new("~/Desktop/demo.taskpaper")
proj = TaskPaperItem.new("My project:")
doc.add_child(proj)

# Add some items to the project
proj.add_child("- A task")
proj.add_child("- Another task")

# Nest items
third_task = proj.add_child("- A third task @cool")
third_task.add_child("A note with a link: http://mattgemmell.com/")

# Manually create an item and add it
new_child = TaskPaperItem.new("- Just another task")
third_task.add_child(new_child)

proj.add_child("- A fourth task")

# Get a flat list of all tasks in the document, then output their titles
tasks = doc.children_flat(TaskPaperItem::TYPE_TASK)
task_titles = tasks.collect { |item| item.title }
puts task_titles

# To output doc in TaskPaper format
# puts doc.to_text

# To save the file (in TaskPaper format) to the path we used when creating it
# doc.save_file
