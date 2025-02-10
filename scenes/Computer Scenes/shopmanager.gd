extends Node

var emails: Array = []  # Stores all emails
@onready var categories_list_container: Node = $ScrollContainer/ShopCategoriesListContainer
@export var item_button_scene: PackedScene

# Change the variable name to avoid conflict with the class name
@export var item_class : Resource  # Set the type to Resource so it can hold the class

# Function to add emails
func add_item(sender: String, subject: String, contents: String):
	pass
	#var item = item_class.new()  # Create an email object
	#emails.append(email)  # Add to list
	#display_email(email)  # Add to UI

# adds items to shop ui
func display_item(): #insert item as a parameter
	var item_button = item_button_scene.instantiate()  
	#email_button.set_email(email) 
	#var panel = email_button.get_node("Panel")
	#panel.visible = false
	#item_button.pressed.connect(func(): show_email_details(email, email_button))  
	categories_list_container.add_child(item_button) 
	

# shows upon click
#func show_email_details(email: Email, email_button: Button): #confirm item buy???
	

func _ready():
	pass
	#add_item
