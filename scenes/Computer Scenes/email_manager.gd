extends Node

var emails: Array = []
var categorized_emails: Dictionary = GameManager.categorized_emails
var current_category: String = "main"
var current_inbox_button: Button = null
@onready var email_list_container: Node = $ScrollContainer/EmailsListContainer
@export var email_button_scene: PackedScene

@onready var inbox_list_container: Node = $InboxButtonsList
@export var inbox_button_scene: PackedScene
@export var email_folder : String = "res://resources/emails/"
@export var email_class : Resource
var buttoncolor : String = "#e255aa"
var selectedbuttoncolor : String = "#cc7aaa"
var remaining_order_emails = GameManager.remaining_order_emails # NOT VALIDATED YET
var completed_order_emails = GameManager.completed_order_emails
var all_lore_emails = GameManager.all_lore_emails
var all_tutorial_emails = GameManager.all_tutorial_emails
var saved_day : int = 1
func _ready():
	load_emails()
	create_inbox_buttons()
	#print(emails)
	display_category_emails(current_category) # default view to "main"

func _process(delta: float) -> void:
	for email in emails:
		if email not in completed_order_emails and email not in remaining_order_emails and !email.tutorial and email not in all_lore_emails:
			#email is not loaded in yet and is NOT a tutorial email and NOT a lore email
			remaining_order_emails.append(email)
	if saved_day != GameManager.game_time["day"]: # new day
		var selected_new_emails = select_random_emails()
		print("selecting 5 new emails")
		remaining_order_emails.erase(selected_new_emails)
		for eachemail in selected_new_emails:
			categorized_emails["main"].append(eachemail)
			print("appended email", eachemail)
		saved_day = GameManager.game_time["day"]
	
	
func select_random_emails():
	# selects 5 random valid emails, or all of them if theres less than 5 valid ones
	var valid_emails = remaining_order_emails.filter(func(email): return email.check_valid())
	if valid_emails.is_empty():
		valid_emails = completed_order_emails.filter(func(email): return email.check_valid())
	valid_emails.shuffle()
	return valid_emails.slice(0, 5)

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
		if email.check_valid():
			display_email_button(email)
	current_category = category
	

func load_emails():
	# load all email resources
	var dir:DirAccess = DirAccess.open(email_folder)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".remap"):
				file_name = file_name.trim_suffix(".remap")
			if file_name.ends_with(".tres"):
				var email_path = email_folder + file_name
				var email = load(email_path)
				if email and email is Email:
					emails.append(email)
					categorized_emails[email.category].append(email)
					if email.lore_only:
						all_lore_emails.append(email)
					if email.tutorial:
						all_tutorial_emails.append(email)
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
	if email.day <= game_time["day"]: # day is right/has passed
		if email.hour <= game_time["hour"]: # hour is right/has passed
			if email.minute <= game_time["minute"]:
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
	#is_read_color(email, email_button)
	
	var accept_button = email_button.find_child("Accept")
	var reject_button = email_button.find_child("Decline")
	var fulfill_texture = email_button.find_child("FulfillTexture")
	var fulfill_button = fulfill_texture.find_child("Fulfill")
	# order accept/reject
	if email.attached_order != null and !email.attached_order.responded:
		if accept_button:
			accept_button.pressed.connect(func(): order_accept(email))
		if reject_button:
			if !email.tutorial:
				reject_button.pressed.connect(func(): order_reject(email))
	elif email.attached_order != null and email.attached_order.responded and email.attached_order.is_accepted and not email.attached_order.is_completed:
		fulfill_texture.visible = true
		accept_button.visible = false
		reject_button.visible = false
		fulfill_button.pressed.connect(func(): fulfill_order(email))
		#change_email_category(email, "orders")
		#display_category_emails(current_category)
	elif email.attached_order != null and email.attached_order.is_completed:
		change_email_category(email, "archive")
		#display_category_emails(current_category)
		fulfill_texture.visible = false
		accept_button.visible = false
		reject_button.visible = false
	else: # no attached order OR order has been responded to
		accept_button.visible = false
		reject_button.visible = false
		# if email.attached_order.responded:
			#TODO: maybe add "you rejected" or "you accepted+fulfilled"
		
# Shows expanded email
func show_email_details(email: Email, email_button: Button):
	var panel = email_button.get_node("Panel")
	email.is_read = true
	#is_read_color(email, email_button)
	panel.visible = !panel.visible
	if panel.visible:
		email_button.custom_minimum_size = Vector2(1920,1080)
	else:
		email_button.custom_minimum_size = Vector2(1920,300)
	
	
func order_accept(email: Email):
	var order = email.attached_order
	OrderManager.accept_order(order)
	OrderManager.give_player_starting_items(order)
	change_email_category(email, "orders")
	display_category_emails(current_category)
	# TODO: save order accept day, check this later
	
	
func order_reject(email: Email):
	var order = email.attached_order
	OrderManager.reject_order(order)
	# move inbox
	change_email_category(email, "archive")
	display_category_emails(current_category)
	remaining_order_emails.append(email) # readd back to remaining order emails to be reselected
	
func fulfill_order(email: Email):
	if OrderManager.fulfill_order(email.attached_order):
		change_email_category(email, "archive")
		display_category_emails(current_category)
		if !email.tutorial and email not in all_lore_emails:
			completed_order_emails.append(email)
	
func get_emails_in_category(category: String):
	return categorized_emails[category]
#func is_read_color(email: Email, email_button: Button):
	#if email.is_read:
		#var style = StyleBoxFlat.new()
		#style.bg_color = Color(selectedbuttoncolor)
		#email_button.set("theme_override_styles/normal", style)
