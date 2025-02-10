class_name Email
extends Object

var sender: String
var subject: String
var contents: String
var category: String
# orders (active only/unopened), main (main lore), junk, social, archive (completed + declined orders)
var is_read: bool

func _init(sender: String, subject: String, contents: String, category: String = "main", is_read: bool = false):
	self.sender = sender
	self.subject = subject
	self.contents = contents
	self.category = category
	self.is_read = is_read

func mark_as_read():
	is_read = true
