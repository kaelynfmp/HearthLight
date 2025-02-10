extends Node

var emails: Array = []
@onready var email_list_container: Node = $ScrollContainer/EmailsListContainer
@export var email_button_scene: PackedScene

@export var email_class : Resource  

func add_email(sender: String, subject: String, contents: String):
	var email = email_class.new(sender, subject, contents)  
	emails.append(email)  # add to list
	display_email(email)  # add to UI

# adds email to UI as a button
func display_email(email: Email):
	var email_button = email_button_scene.instantiate() 
	email_button.set_email(email) 
	var panel = email_button.get_node("Panel")
	panel.visible = false
	email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	email_list_container.add_child(email_button)  # Add to UI list
	

# Shows expanded email
func show_email_details(email: Email, email_button: Button):
	var panel = email_button.get_node("Panel")
	print("Toggled panel visibility")
	print("test")
	email.is_read = true 
	panel.visible = !panel.visible
	if panel.visible:
		email_button.custom_minimum_size = Vector2(1920,1080)
	else:
		email_button.custom_minimum_size = Vector2(1920,300)
	

func _ready():
	print("EmailManager is ready!")
	add_email("John Testsender", "Test Subject", "This is the start of the email. This is the end of the email.")
	add_email("Janethaniel Testerson", "The Longest Super Long Subject Test", "This is the contents of the email.")
	add_email("sender", "subject", "This is the contents of the email.")
	add_email("sender", "subject", "This is the contents of the email.")
	add_email("sender", "subject", "This is the contents of the email.")
	add_email("sender", "subject", "This is the contents of the email.")
