extends Node

var emails: Array = []
var categorized_emails: Dictionary = GameManager.categorized_emails
var current_category: String = "main"
var current_inbox_button: Button = null
@onready var email_list_container: Node = $EmailScrollContainer/EmailsListContainer
@onready var email_scroll_container: Node = $EmailScrollContainer
@export var email_button_scene: PackedScene
@onready var inbox_list_container: Node = $InboxButtonsList
@export var inbox_button_scene: PackedScene
@export var email_folder : String = "res://resources/emails/"
@export var email_class : Resource
var buttoncolor : String = "#e255aa"
var selectedbuttoncolor : String = "#cc7aaa"
var all_order_emails = GameManager.all_order_emails
var all_lore_emails = GameManager.all_lore_emails
var all_tutorial_emails = GameManager.all_tutorial_emails
var all_bankruptcy_emails = GameManager.all_bankruptcy_emails
var saved_day : int = 1
var last_bankruptcy_sent: int = 0
var default_button_texture:Texture
var currently_open_emails = []
var to_close_emails:Array[Email] = []
var prev_random_emails:Array[Email]

func _ready():
	load_emails()
	create_inbox_buttons()
	#print(emails)
	for email in emails:
		if !email.category:
			email.category = "main"
	
	add_valid_tutorial_emails()
	add_valid_lore_emails()
	display_category_emails(current_category) # default view to "main"

func _process(delta: float) -> void:
	# add new emails 
	
	# upon previous tutorial email completed, insert next one
	add_valid_tutorial_emails()
	
	# upon valid, insert lore email
	add_valid_lore_emails()

	# new randomly selected orders every day
	if saved_day != GameManager.game_time["day"]: # new day
		# Duplicate so that we don't erase the array we're actively working on
		for email:Email in categorized_emails["main"].duplicate():
			if email.displayed and email.attached_order != null and not email.tutorial:
				to_close_emails.append(email)
				categorized_emails["main"].erase(email)
		
		var selected_new_emails:Array[Email] = select_random_emails()
		for eachemail in selected_new_emails:
			#print("inserting...", eachemail.sender)
			#print("appended email", eachemail)
			if eachemail in categorized_emails["archive"]:
				# Remove from archive, to prevent archive piling up with the same email
				change_email_category(eachemail, "main")
			else:
				categorized_emails["main"].insert(0,eachemail)
		# check due dates BEFORE updating saved day
		for eachemail:Email in categorized_emails["orders"]:
			check_email_failed(eachemail)
			
		display_nearest_category(current_category)
		saved_day = GameManager.game_time["day"]

	# check for bankruptcy and send email with money if so
	# only works once per day, only sends if bankrupt
	# bankruptcy emails are removed at day start before this, so they cannot be stacked up
	try_send_bankruptcy()
		
## Selects random emails from the pool of all valid order emails, prioritizing emails that have yet to be completed
func select_random_emails(random_amount: int = GameManager.random_email_amount) -> Array[Email]:
	var random_emails:Array[Email]
	var remaining:int = random_amount
	# Prioritize emails that have yet to be completed
	# Remove emails we saw in the last batch
	var select_from:Array[Email] = all_order_emails.filter(func(email: Email): return email not in prev_random_emails and email.check_valid() and not email.attached_order.is_completed)
	select_from = select_from.filter(func(email: Email): return )
	if select_from.size() < remaining:
		if not select_from.is_empty():
			for index in range(select_from.size()):
				random_emails.append(select_from[index])
				remaining -= 1
	else:
		var shuffled_emails:Array[Email] = select_from.duplicate()
		shuffled_emails.shuffle()
		random_emails.append(shuffled_emails[0])
		random_emails.append(shuffled_emails[1])
		remaining = 0
	
	# If we haven't yet filled our random quota, we can not try to start pulling from emails that /have/ been completed
	if remaining > 0:
	# Remove emails we saw in the last batch
		var select_from_all:Array[Email] = all_order_emails.filter(func(email): return email not in prev_random_emails and email.check_valid())
		var shuffled_emails:Array[Email] = select_from_all.duplicate()
		shuffled_emails.shuffle()
		for index in range(min(remaining, shuffled_emails.size())):
			random_emails.append(shuffled_emails[index])
			remaining -= 1
	
	# If we STILL haven't filled our random quota, we can pull from emails we saw in the last batch if they are still valid
	if remaining > 0:
		prev_random_emails = prev_random_emails.filter(func(email: Email): return email.check_valid())
		prev_random_emails.shuffle()
		for index in range(min(remaining, prev_random_emails.size())):
			random_emails.append(prev_random_emails[index])
			remaining -= 1

	random_emails.shuffle()
	prev_random_emails = random_emails.duplicate()
	return random_emails

func create_inbox_buttons():
	for category in categorized_emails.keys():
		if categorized_emails[category].size() >= 0:
			var inbox_button = inbox_button_scene.instantiate()
			inbox_button.text = category.capitalize()
			inbox_button.category = category
			default_button_texture = inbox_button.sprite.texture
			match (inbox_button.text):
				"Orders":
					inbox_button.main_texture = preload("res://resources/sprites/emails/emailButton1.png")
					inbox_button.name = "OrdersButton"
				"Main":
					inbox_button.main_texture = preload("res://resources/sprites/emails/emailButton2.png")
					set_current_inbox_button(inbox_button)
					inbox_button.name = "MainButton"
				"Spam":
					inbox_button.main_texture = preload("res://resources/sprites/emails/emailButton3.png")
					inbox_button.name = "SpamButton"
				"Archive":
					inbox_button.main_texture = preload("res://resources/sprites/emails/emailButton4.png")
					inbox_button.name = "ArchiveButton"
			inbox_button.pressed.connect(func():
				display_category_emails(category)
				set_current_inbox_button(inbox_button))
			inbox_list_container.add_child(inbox_button)
			
func set_current_inbox_button(button: Button):
	current_inbox_button = button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(buttoncolor)
	for eachbutton in inbox_list_container.get_children():
		if eachbutton is Button:
			eachbutton.sprite.texture = eachbutton.main_texture
		
	# Calling deferred here ensures that the main texture has been set first
	current_inbox_button.sprite.call_deferred("set_texture", default_button_texture)

func display_category_emails(category: String):
	# clear current email list
	if category != current_category:
		currently_open_emails = []
	for child in email_list_container.get_children():
		child.queue_free()
	#print("        \n ------- \n")
	for email in categorized_emails[category]:
		if email.check_valid():
			#print(email.sender, " is valid and will display now")
			display_email_button(email)
		elif category == "archive":
			display_email_button(email)
	current_category = category

	set_current_inbox_button(inbox_list_container.get_children()[inbox_list_container.get_children().find_custom(\
		func(child): return child.name == category.capitalize() + "Button")])
	
## load all email resources
func load_emails():
	var email_strings = Utility.load_path("res://resources/emails")
	for email_string in email_strings:
		var email = load(email_string)
		if email and email is Email:
			emails.append(email)
			if email.attached_order == null:
				all_lore_emails.append(email)
			else:
				if email.tutorial:
					all_tutorial_emails.append(email)
				elif email.bankruptcy:
					all_bankruptcy_emails.append(email)
				else:
					all_order_emails.append(email)
			#display_email_button(email)  # display the email in the UI
			if email.attached_order != null:
				OrderManager.email_by_order[email.attached_order] = email

func change_email_category(email: Email, new_category: String):
	# remove from old inbox
	if email in categorized_emails[email.category]:
		categorized_emails[email.category].erase(email)
		
		# change email's category, display in new inbox
		email.category = new_category
		categorized_emails[new_category].insert(0,email)
	if new_category == "archive":
		email.is_read = true
		email.archived = true
	else:
		email.archived = false
	
func is_email_time_reached(email: Email) -> bool:
	var game_time = GameManager.game_time
	if email.day <= game_time["day"]: # day is right/has passed
		if email.hour <= game_time["hour"]: # hour is right/has passed
			if email.minute <= game_time["minute"]:
				return true
	
	return false

# adds email to UI as a button
func display_email_button(email: Email):
	email.displayed = true
	var email_button = email_button_scene.instantiate()
	email_button.set_email(email)
	var panel = email_button.get_node("Panel")
	#panel.visible = false
	email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	
	if email in currently_open_emails:
		show_email_details(email,email_button)
		
	if email in to_close_emails:
		if email in currently_open_emails:
			# Close the email, and remove the read state
			show_email_details(email,email_button)
		email.is_read = false
		to_close_emails.erase(email)
	email_list_container.add_child(email_button)
	# make email read
	#is_read_color(email, email_button)
	var accept_button = email_button.find_child("Accept")
	var reject_button = email_button.find_child("Decline")
	var fulfill_texture = email_button.find_child("FulfillTexture")
	var fulfill_button = fulfill_texture.find_child("Fulfill")
	if email.bankruptcy and email.archived:
		fulfill_texture.visible = false
		accept_button.visible = false
		reject_button.visible = false
	# order accept/reject
	if email.attached_order != null and !email.attached_order.responded:
		if accept_button:
			accept_button.pressed.connect(func(): order_accept(email, accept_button, reject_button))
		if reject_button:
			if !email.tutorial:
				reject_button.disabled = false
				reject_button.pressed.connect(func(): order_reject(email, accept_button, reject_button))
	if email.attached_order == null:
		fulfill_texture.visible = true
		fulfill_button.button_sound = AudioManager.BUTTON.CLICK
		fulfill_button.text = "Archive"
		fulfill_button.pressed.connect(func(): fulfill_order(email))
	if email.attached_order != null and email.attached_order.responded and email.attached_order.is_accepted and not email.attached_order.is_completed:
		fulfill_texture.visible = true
		accept_button.visible = false
		reject_button.visible = false
		fulfill_button.pressed.connect(func(): fulfill_order(email))
		#change_email_category(email, "orders")
		#display_category_emails(current_category)
	if email.attached_order != null and email.attached_order.is_completed:
		change_email_category(email, "archive")
		#display_category_emails(current_category)
		fulfill_texture.visible = false
		accept_button.visible = false
		reject_button.visible = false
	if !email.attached_order or email.attached_order.responded: #  no order or order has been responded to
		accept_button.visible = false
		reject_button.visible = false
		# if email.attached_order.responded:
			#TODO: maybe add "you rejected" or "you accepted+fulfilled"
		
# Shows expanded email
func show_email_details(email: Email, email_button: Button):
	var panel = email_button.get_node("Panel")
	email.is_read = true
	#print(email.sender, "is read")
	#is_read_color(email, email_button)
	panel.visible = !panel.visible
	if panel.visible:
		currently_open_emails.append(email)
		email_button.custom_minimum_size = Vector2(1920,1019)
	else:
		currently_open_emails.erase(email)
		email_button.custom_minimum_size = Vector2(1920,300)
	
	
func display_nearest_category(category: String):
	if not categorized_emails[category].any(func(email: Email): return email.check_valid()):
		# Find first category with stuff in it
		var category_name:String = categorized_emails.keys()[categorized_emails.keys().find_custom(\
			func(category_string: String): return categorized_emails[category_string].any(\
				func(email: Email): return email.check_valid()))]
		display_category_emails(category_name)
	else:
		display_category_emails(category)

func order_accept(email: Email, accept_button: Button = null, reject_button: Button = null):
	var order = email.attached_order
	if accept_button and reject_button:
		accept_button.visible = false
		reject_button.visible = false
	if !email.bankruptcy:
		OrderManager.accept_order(order)
		OrderManager.give_player_starting_items(order)
		change_email_category(email, "orders")
		email.is_read = false
	else:
		OrderManager.give_player_starting_items(order)
		fulfill_order(email)
		email.is_read = false
		change_email_category(email, "archive")
	display_nearest_category(current_category)
					
	# TODO: save order accept day, check this later
	
	
func order_reject(email: Email, accept_button: Button = null, reject_button: Button = null):
	var order = email.attached_order
	if accept_button and reject_button:
		accept_button.visible = false
		reject_button.visible = false
	OrderManager.reject_order(order)
	# move inbox
	change_email_category(email, "archive")
	display_nearest_category(current_category)
	
func fulfill_order(email: Email):
	if email.attached_order == null:
		change_email_category(email, "archive")
		display_nearest_category(current_category)
	else:
		if OrderManager.fulfill_order(email.attached_order):
			email.is_read = false
			change_email_category(email, "archive")
			if email.tutorial:
				# Immediately show the next emails, so we can go to main instead of archive
				add_valid_tutorial_emails()
				add_valid_lore_emails()
			display_nearest_category(current_category)

func check_email_failed(email: Email) -> bool:
	if saved_day != GameManager.game_time["day"] and email.failable:
		email.failed = true
		email.attached_order.removed.emit()
		order_reject(email)
		#print("email failed")
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
		if email.check_valid() and email not in categorized_emails["main"] and not email.archived:
			categorized_emails["main"].insert(0,email)
			display_category_emails(current_category)

#func add_valid_emails(qty: int):
	#var i = 0
	#for email in remaining_order_emails:
		#while i<qty:
			#if email.check_chain() and email.check_valid() and email not in categorized_emails["main"] and email not in categorized_emails["orders"]:
				#categorized_emails["main"].insert(0,email)
				#display_category_emails(current_category)
			#i+=1

func add_valid_tutorial_emails():
	for email in all_tutorial_emails:
		if email.check_valid() and email not in categorized_emails["main"] and email not in categorized_emails["orders"] and email not in categorized_emails["archive"]:
			categorized_emails["main"].insert(0,email)
			display_category_emails(current_category)

func try_send_bankruptcy() -> void:
	if last_bankruptcy_sent != GameManager.game_time["day"]:
		var valid_bankruptcy_emails = all_bankruptcy_emails.filter(func(email): return email.check_valid()).duplicate()
		if valid_bankruptcy_emails.is_empty(): return
		
		# Sort by currently highest money-giving bankruptcy email
		valid_bankruptcy_emails.sort_custom(func(a, b): return a.attached_order.currency_reward > b.attached_order.currency_reward)
		var bankruptcy_email:Email = valid_bankruptcy_emails[0]
		
		# Send bankruptcy if it would give you more money than you have
		if GameManager.currency < bankruptcy_email.attached_order.currency_reward:
			bankruptcy_email.attached_order.is_completed = false
			if bankruptcy_email in categorized_emails["archive"]:
				# Remove from archive, to prevent archive piling up with the same email
				change_email_category(bankruptcy_email, "main")
			else:
				categorized_emails["main"].insert(0,bankruptcy_email)
			if current_category == "main":
				display_nearest_category(current_category)
			last_bankruptcy_sent = GameManager.game_time["day"]
