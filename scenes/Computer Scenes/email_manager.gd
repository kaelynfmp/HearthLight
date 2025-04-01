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
@export var bankruptcy_email: Email
@export var tutorial_bankruptcy_email: Email
var bankruptcy_copy: Email
var last_bankruptcy_sent: int = 0
func _ready():
	load_emails()
	create_inbox_buttons()
	#print(emails)
	for email in emails:
		if email not in completed_order_emails and email not in remaining_order_emails and email not in all_lore_emails and !email.bankruptcy:
			#email is not loaded in yet and is NOT a tutorial email and NOT a lore email
			if email.tutorial and !email.prerequisite_emails:
				# does not add the very first tutorial email to the remaining emails
				pass
			else:
				remaining_order_emails.append(email)
			
		if email.tutorial:
			if email.check_valid():
				GameManager.categorized_emails["main"].append(email)
	add_valid_lore_emails()
	display_category_emails(current_category) # default view to "main"

func _process(delta: float) -> void:
	# add new emails
	
	# upon previous tutorial email completed, insert next one
	add_valid_tutorial_emails()
	
	# upon valid, insert lore email
	add_valid_lore_emails()
	
	# check for bankruptcy and send email with money if so
	# only works once per day, only sends if bankrupt and you dont have a bankruptcy email in your inbox
	try_send_bankruptcy()
	
	# new randomly selected orders every day
	if saved_day != GameManager.game_time["day"]: # new day
		#print("selecting 2 new emails")
		var selected_new_emails = select_random_emails()
		if len(selected_new_emails)>0:
			remaining_order_emails.erase(selected_new_emails)
			for eachemail in selected_new_emails:
				print("inserting...", eachemail.sender)
				#print("appended email", eachemail)
		

		
		# check due dates BEFORE updating saved day
		for eachemail in categorized_emails["orders"]:
			if check_email_failed(eachemail):
				# TODO: send failure email?
				change_email_category(eachemail,"archive")
			
		display_category_emails(current_category)
		saved_day = GameManager.game_time["day"]
		for email in remaining_order_emails:
			if not email.bankruptcy and email.attached_order:
				print("remaining: ", email.attached_order.order_id)
		for email in completed_order_emails:
			if not email.bankruptcy and email.attached_order:
				print("completed: ", email.attached_order.order_id)
func select_random_emails():
	# selects 2 random valid emails, or all of them if theres less than 2 valid ones
	var select_from = remaining_order_emails
	if select_from.is_empty():
		select_from = completed_order_emails
	
	var valid_emails = select_from.filter(func(email): return email.check_valid())
	valid_emails.shuffle()
	for eachemail in valid_emails:
		select_from.erase(eachemail)
	return valid_emails.slice(0, 2)

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
		elif category == "archive":
			display_email_button(email)
	current_category = category
	
## load all email resources
func load_emails():
	var email_strings = Utility.load_path("res://resources/emails")
	for email_string in email_strings:
		var email = load(email_string)
		if email and email is Email:
			emails.append(email)
			if email.lore_only:
				all_lore_emails.append(email)
			if email.tutorial:
				all_tutorial_emails.append(email)
			#display_email_button(email)  # display the email in the UI
			if email.attached_order != null:
				OrderManager.email_by_order[email.attached_order] = email

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
	if email.bankruptcy and email.attached_order.is_accepted:
		fulfill_texture.visible = false
		accept_button.visible = false
		reject_button.visible = false
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
	if !email.bankruptcy:
		OrderManager.accept_order(order)
		OrderManager.give_player_starting_items(order)
		change_email_category(email, "orders")
		email.is_read = false
	else:
		OrderManager.give_player_starting_items(order)
		fulfill_order(email)
		email.attached_order.is_accepted = true
		change_email_category(email, "archive")
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
		email.is_read = false
		change_email_category(email, "archive")
		display_category_emails(current_category)
		if !email.tutorial and !email.bankruptcy and email not in all_lore_emails:
			print("adding to completed...")
			completed_order_emails.append(email)
		if email in remaining_order_emails:
			print("removing from remaining")
			remaining_order_emails.erase(email)

func check_email_failed(email: Email) -> bool:
	if saved_day != GameManager.game_time["day"] and email.failable:
		email.failed = true
		order_reject(email)
		#print("email failed")
		remaining_order_emails.append(email)
		return true
	return false

func get_emails_in_category(category: String):
	return categorized_emails[category]
#func is_read_color(email: Email, email_button: Button):
	#if email.is_read:
		#var style = StyleBoxFlat.new()
		#style.bg_color = Color(selectedbuttoncolor)
		#email_button.set("theme_override_styles/normal", style)

func add_valid_lore_emails():
	for email in all_lore_emails:
		if email.check_valid() and email not in categorized_emails["main"]:
			categorized_emails["main"].insert(0,email)

func add_valid_tutorial_emails():
	for email in all_tutorial_emails:
		if email.check_chain() and email not in categorized_emails["main"] and email not in categorized_emails["orders"] and email not in categorized_emails["archive"]:
			categorized_emails["main"].insert(0,email)

func try_send_bankruptcy():
	if last_bankruptcy_sent != GameManager.game_time["day"]: 
		#print(GameManager.currency < 10, !bankruptcy_email.check_chain(), categorized_emails["main"].filter(func(email: Email): return email.bankruptcy).is_empty())
		if GameManager.currency < 10 and !bankruptcy_email.check_chain() and categorized_emails["main"].filter(func(email: Email): return email.bankruptcy).is_empty():
			# tutorial not done yet, send tutorial bankruptcy
			bankruptcy_copy = tutorial_bankruptcy_email.duplicate(true)
		# normal bankruptcy
		if GameManager.currency < 100 and GameManager.game_time["day"]% 3 == 0 and GameManager.game_time["day"] >= 3 and categorized_emails["main"].filter(func(email: Email): return email.bankruptcy).is_empty() and bankruptcy_email.check_chain():
			#print("bankruptcy activated")
			bankruptcy_copy = bankruptcy_email.duplicate(true)
		
		# if bankruptcy triggered
		if bankruptcy_copy:
			bankruptcy_copy.attached_order.is_accepted = false
			categorized_emails["main"].insert(0,bankruptcy_copy)
			last_bankruptcy_sent = GameManager.game_time["day"]
