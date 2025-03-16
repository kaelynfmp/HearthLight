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
@export var day: int 
@export_range(8, 23, 1) var hour: int # min 0, max 30, step 1

@export_range(0, 59, 1) var minute: int
@export var is_read: bool
@export var attached_order: Order

var tutorial: bool # Has no time limit. Anything not set to tutorial == true will have a limit of the midnight of the day you found it
var has_start_time: bool
# WEIRD FAIL CHECKING STUFF WE DISCUSSED AT TOP OF WHITEBOARD
var failable: bool 
var failed: bool
var prereqs_must_fail: bool # This is for conditions where an email only appears after something /fails/, something Everett requested


@export var prerequisite_emails: Array[Email]
func mark_as_read():
	is_read = true

func check_valid() -> bool:
	if failable and failed:
		# This email is not viewable again, as it failed
		return false
	if has_start_time and !GameManager.is_after_date(day, hour, minute):
		# If it has a start time, and that start time hasn't been met
		return false
	#TODO:uncomment following blocks, commented due to no prereq emails field yet
	#if !prerequisite_emails.all(func(email: Email): return email in GameManager.categorized_emails["archive"]):
		# Prerequisite condition not met, some of the prereq emails are not archived. Checks the archive instead
		# of completed_order_emails, because the pre-requisite could theoretically be a tutorial or lore email
		#return false
	#if !prereqs_must_fail and !prerequisite_emails.filter(func(email: Email): return failable and failed).is_empty():
		#return false
	#if prereqs_must_fail and prerequisite_emails.filter(func(email: Email): return failable and failed).is_empty():
		#return false
	# --- UNCOMMENT UNTIL HERE
	return true
