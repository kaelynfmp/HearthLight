class_name Email
extends Resource
@export_category("Email Contents")
@export var sender: String
@export var subject: String
@export_multiline var contents: String
@export_enum("orders", "main", "junk", "social", "archive")
var category: String
# orders (active only/unopened), main (main lore), junk, social, archive (completed + declined orders)

@export_category("Internal Details")
@export var prerequisite_emails: Array[Email]
@export_range(0, 30, 1) var day: int # min 0, max 30, step 1
@export var hour: int
@export var minute: int
@export var is_read: bool
@export var attached_order: Order
		
func mark_as_read():
	is_read = true
