class_name Email
extends Resource
@export_category("Email Contents")
@export var sender: String
@export var email: String
@export var subject: String
@export_multiline var contents: String
@export_enum("orders", "main", "junk", "social", "archive")
var category: String = "main"
# orders (active only/unopened), main (main lore), junk, social, archive (completed + declined orders)

@export_category("Internal Details")
@export var prerequisite_emails: Array[Email]
@export var day: int 
@export_range(8, 23, 1) var hour: int # min 0, max 30, step 1
@export_range(0, 59, 1) var minute: int
@export var is_read: bool
@export var attached_order: Order

@export var tutorial: bool # Has no time limit. Anything not set to tutorial == true will have a limit of the midnight of the day you found it
@export var has_start_time: bool
# WEIRD FAIL CHECKING STUFF WE DISCUSSED AT TOP OF WHITEBOARD
@export var failable: bool 
@export var failed: bool
@export var prereqs_must_fail: bool # This is for conditions where an email only appears after something /fails/, something Everett requested
@export var bankruptcy: bool = false
var displayed: bool = false
## Whether or not the email was archived, only used visually so we don't have to navigate the list every frame
var archived: bool = false


func check_valid() -> bool:
	if failable and failed:
		# This email is not viewable again, as it failed
		return false
	if failable and attached_order.is_completed:
		# Failable emails cannot be viewed again after being completed, to make chains not appear again
		return false
	if has_start_time and !GameManager.is_after_date(day, hour, minute):
		# If it has a start time, and that start time hasn't been met
		return false
	if !prerequisite_emails.all(func(_email: Email): \
		return (_email.attached_order and (_email.attached_order.is_completed or (prereqs_must_fail and _email.failable and _email.failed))) or (!_email.attached_order and _email.is_read)):
		# Prereq not met
		# Prerequisite condition not met, some of the prereq emails are not archived. Checks the archive instead
		# of completed_order_emails, because the pre-requisite could theoretically be a tutorial or lore email
		return false
	if !prereqs_must_fail and prerequisite_emails.any(func(_email: Email): return _email.failable and _email.failed):
		# not a failure email AND failed prereq emails list is NOT EMPTY
		# aka not a failure email and prereqs have been failed
		return false
	if prereqs_must_fail and !prerequisite_emails.all(func(_email: Email): return _email.failable and _email.failed):
		# failure email and prereqs are not failed (if they exist)
		return false
	
	#if self in GameManager.categorized_emails["orders"] or self in GameManager.categorized_emails["main"] or !check_chain(): # if NOT a failure email, check if prereq emails are failed: return false, otw true
	#	return false
	return true
