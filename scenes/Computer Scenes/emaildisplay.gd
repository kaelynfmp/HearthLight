extends Button

var email: Email

@export var sender_label: Label  
@export var subject_label: Label  
@export var sender_dropdown: Label
@export var subject_dropdown: Label
@export var blurb_label: Label
@export var content: Label
@export var expand_panel: Panel  # expanded email content

func set_email(new_email: Email):
	email = new_email
	sender_label.text = set_limited_text(email.sender)
	subject_label.text = set_limited_text(email.subject, 28)
	
	blurb_label.text = set_limited_text(email.contents.split("\n")[0])
	sender_dropdown.text = email.sender
	subject_dropdown.text = email.subject
	content.text = email.contents
	expand_panel.visible = false

func set_limited_text(input_text: String, limit: int = 16) -> String:
	if input_text.length() > limit:
		return input_text.substr(0, limit) + "..." 
	else:
		return input_text
	
