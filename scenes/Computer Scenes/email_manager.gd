extends Node

var emails: Array = []
var categorized_emails: Dictionary = {
	"orders": [],
	"main": [],
	"junk": [],
	"social": [],
	"archive": []
}
var current_category: String = "main"
var current_inbox_button: Button = null
@onready var email_list_container: Node = $ScrollContainer/EmailsListContainer
@export var email_button_scene: PackedScene

@onready var inbox_list_container: Node = $InboxButtonsList
@export var inbox_button_scene: PackedScene

@export var email_folder : String = "res://resources/emails/"
@export var email_class : Resource

@export var order_manager: OrderManager

var buttoncolor : String = "#e255aa"
var selectedbuttoncolor : String = "#cc7aaa"

func _ready():
	load_emails()
	create_inbox_buttons()
	print(emails)
	display_category_emails(current_category) # default view to "main"

func create_inbox_buttons():
	for category in categorized_emails.keys():
		if categorized_emails[category].size() >= 0:
			var inbox_button = inbox_button_scene.instantiate()
			inbox_button.text = category.capitalize()
			if(inbox_button.text == "Main"):
				set_current_inbox_button(inbox_button)
			inbox_button.pressed.connect(func():
				display_category_emails(category)
				set_current_inbox_button(inbox_button))
			inbox_list_container.add_child(inbox_button)
			
func set_current_inbox_button(button: Button):
	current_inbox_button = button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(buttoncolor)
	for eachbutton in inbox_list_container.get_children():
		eachbutton.set("theme_override_styles/normal", style)
	
	var selectedstyle = StyleBoxFlat.new()
	selectedstyle.bg_color = Color(selectedbuttoncolor)
	current_inbox_button.set("theme_override_styles/normal", selectedstyle)
	
func display_category_emails(category: String):
	# clear current email list
	for child in email_list_container.get_children():
		child.queue_free()
	
	for email in categorized_emails[category]:
		if is_email_time_reached(email):
			display_email_button(email)
	current_category = category
	

func load_emails():
	# load all email resources
	var dir = DirAccess.open(email_folder)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var email_path = email_folder + file_name
				var email = load(email_path)
				if email and email is Email:
					emails.append(email)
					categorized_emails[email.category].append(email)
					#display_email_button(email)  # display the email in the UI
			file_name = dir.get_next()
		dir.list_dir_end()

func change_email_category(email: Email, new_category: String):
	# remove from old inbox
	if email in categorized_emails[email.category]:
		categorized_emails[email.category].erase(email)
		
	# change email's category, display in new inbox
	email.category = new_category
	categorized_emails[new_category].append(email)
	
func is_email_time_reached(email: Email) -> bool:
	var game_time = GameManager.game_time 
	print(game_time)
	print(email.day,"D ", email.hour, "H ", email.minute, "M")
	if email.day <= game_time["day"]: # day is right/has passed
		if email.hour <= game_time["hour"]: # hour is right/has passed
			if email.minute <= game_time["minute"]:
				print(email.contents, " is ready to be displayed!")
				return true
	
	return false

# adds email to UI as a button
func display_email_button(email: Email):
	var email_button = email_button_scene.instantiate()
	email_button.set_email(email)
	var panel = email_button.get_node("Panel")
	panel.visible = false
	email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	email_list_container.add_child(email_button) 
	
	# make email read
	is_read_color(email, email_button)
	
	var accept_button = email_button.find_child("Accept")
	var reject_button = email_button.find_child("Decline")
	# order accept/reject
	if email.attached_order and !email.attached_order.responded:
		if accept_button:
			accept_button.pressed.connect(func(): order_accept(email))
		if reject_button:
			reject_button.pressed.connect(func(): order_reject(email))
	else: # no attached order OR order has been responded to
		accept_button.visible = false
		reject_button.visible = false
		# if email.attached_order.responded:
			#TODO: maybe add "you rejected" or "you accepted+fulfilled"
		
# Shows expanded email
func show_email_details(email: Email, email_button: Button):
	var panel = email_button.get_node("Panel")
	print("Toggled panel visibility")
	print("test")
	email.is_read = true
	is_read_color(email, email_button)
	panel.visible = !panel.visible
	if panel.visible:
		email_button.custom_minimum_size = Vector2(1920,1080)
	else:
		email_button.custom_minimum_size = Vector2(1920,300)
	
	
func order_accept(email: Email):
	var order = email.attached_order
	order.is_accepted = true
	order.responded = true
	print("Accepted order")
	# TODO: possibly move to "in progress"
	# TODO: check order fulfillment
	
func order_reject(email: Email):
	var order = email.attached_order
	email.attached_order.is_accepted = false
	order.responded = true
	print("Rejected order")
	# move inbox
	change_email_category(email, "archive")
	display_category_emails(current_category)
	
func is_read_color(email: Email, email_button: Button):
	if email.is_read:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(selectedbuttoncolor)
		email_button.set("theme_override_styles/normal", style)
