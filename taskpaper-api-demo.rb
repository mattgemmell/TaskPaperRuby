#!/usr/bin/ruby

require_relative 'src/taskpaperdocument'

# Make a new document and add a project
doc = TaskPaperDocument.new("~/Desktop/demo.taskpaper") # will be loaded if it exists
proj = TaskPaperItem.new("My project:")
doc.add_child(proj)

# Add some items to the project
proj.add_child("- A task")
proj.add_child("- Another task")

# Nest items
third_task = proj.add_child("- A third task @cool")
third_task.add_child("A note with a link: http://mattgemmell.com/")

# Manually create an item, add it, and mark it as done
new_child = TaskPaperItem.new("- Just another task")
third_task.add_child(new_child)
new_child.set_done

proj.add_child("- A fourth task")

# Get a flat list of all tasks in the document that aren't done yet
tasks_to_do = doc.all_tasks_not_done

# Output our tasks with the names of their containing projects
puts tasks_to_do.map { |t| "#{t.title} (#{t.project.title})" }

# To get all tasks that aren't done yet and are due today (or earlier)
# puts doc.due_today.map { |t| t.title }

# To output doc in TaskPaper format
# puts doc.to_text

# To save the file (in TaskPaper format) to the path we used when creating it
# doc.save_file
