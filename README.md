# TaskPaperRuby

by [Matt Gemmell](http://mattgemmell.com/)


## What is it?

It's a Ruby script that lets you create and edit [TaskPaper](http://www.taskpaper.com)-format files. It can also export TaskPaper files to HTML and CSS, with [Less](http://lesscss.org)-based auto-conversion of your TaskPaper 3 theme.


## What are its requirements?

- Ruby
- [optionally] [Less CSS](http://lesscss.org)

To install Less on Mac OS X, the simplest way is:

1. Install [Homebrew](http://brew.sh) (instructions on that page).
2. Use Homebrew to install [npm](https://nodejs.org/): `brew install npm` in Terminal.
3. Use npm to install Less: `npm install -g less` in Terminal.
	
Now you can use Less via `lessc` in Terminal. If you don't install Less, this script will use a default theme instead.


## What does it do?

It does a few things:

1. Lets you open, edit, save, and create TaskPaper files.
2. Exports TaskPaper files to HTML and CSS.
3. Auto-converts your own [TaskPaper theme](http://guide.taskpaper.com/creating_themes.html) to use with the HTML.

Here's what it makes of [my TaskPaper theme](http://mattgemmell.com/taskpaper-3/). This is the original file in TaskPaper:

![TaskPaper file](https://c2.staticflickr.com/2/1570/25426422743_ac5c3be362_c.jpg)

And here's the resulting HTML file:

![HTML export](https://c2.staticflickr.com/2/1473/25962552091_95623b3731_c.jpg)

You'll probably want to tweak the resulting CSS, but this should at least get you started.

It also includes a series of plugins to modify the HTML (or text) output. For example, it'll render basic span-level [Markdown](https://en.wikipedia.org/wiki/Markdown) (like _emphasis_ / **emphasis** and `backticked code`), transform a few text emoticons into emoji, and substitute a few tag names/values with icons. You can enable or disable plugins in the `taskpaper-to-html.rb` file.


## How do I use it?

###To convert a given TaskPaper file to HTML

Just run this command, with appropriate values:

`ruby taskpaper-to-html.rb ~/Documents/sample.taskpaper ~/Desktop/output.html`

You can also add an optional third parameter, giving the path to an HTML template file. See the included `template.html` file for what it should look like.

**Note:** This expects that your TaskPaper theme is in the normal place, and that TaskPaper itself is in the usual Applications folder. If that's not the case, you'll want to tweak `taskpaperthemeconverter.rb` first.

###To edit a TaskPaper file via Ruby

	doc = TaskPaperDocument.new("~/Desktop/new.taskpaper")
	doc.add_child(TaskPaperItem.new("Inbox:"))
	item = TaskPaperItem.new("- Do thing @today")
	doc.items[0].add_child(item)
	puts doc.to_text
	doc.save_file

See the `TaskPaperDocument` and `TaskPaperItem` classes for more. You can:

- Manipulate an item's `done` status with `done?`, `set_done`, and `toggle_done`
- Manipulate tags with `tag_value`, `has_tag?`, `set_tag`, and `remove_tag`
- Retrieve or modify content as a whole with `content`
- Inspect and modify types and relationships with `parent`, `children`, `add_child`, `type`, `type_name`, and `inspect`
- Extract metadata with `tags` and `links`
- Inspect position in the hierarchy with `level` (hierarchical), and `effective_level` (taking account of any extra levels of indentation)
- Produce hierarchical representations with `to_text`, `to_tags`, `to_links`, and `to_structure`

And probably more.



## Who made it?

Matt Gemmell (that's me).

- My website is at [mattgemmell.com](http://mattgemmell.com)

- I'm on Twitter as [@mattgemmell](http://twitter.com/mattgemmell)

- This code is on github at [github.com/mattgemmell/TaskPaperRuby](http://github.com/mattgemmell/TaskPaperRuby)


## What license is the code released under?

The [MIT license](http://choosealicense.com/licenses/mit/).

If you need a different license, feel free to ask. I'm flexible about this.


## Why did you make it?

Mostly for fun.


## Can you provide support?

Nope. If you find a bug, please fix it and submit a pull request via github.


## I have a feature request

Feel free to [create an issue](https://github.com/mattgemmell/TaskPaperRuby/issues) with your idea.


## How can I thank you?

You can:

- [Support my writing](http://mattgemmell.com/support-me/).

- Check out [my Amazon wishlist](http://www.amazon.co.uk/registry/wishlist/1BGIQ6Z8GT06F).

- Follow me [on Twitter](http://twitter.com/mattgemmell).
