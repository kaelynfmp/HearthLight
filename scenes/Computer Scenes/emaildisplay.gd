extends Button

var email: Email

@export var sender_label: RichTextLabel 
@export var subject_label: RichTextLabel
@export var sender_dropdown: RichTextLabel
@export var subject_dropdown: RichTextLabel
@export var blurb_label: RichTextLabel
@export var content: RichTextLabel
@export var expand_panel: Panel  # expanded email content
@export var fulfill_button: Button

func _process(_delta: float) -> void:
	if fulfill_button.visible and GameManager.computer_visible and email != null and email.attached_order != null:
		fulfill_button.disabled = !GameManager.player_inventory_has(email.attached_order.required_items, email.attached_order.required_quantities)

func set_email(new_email: Email):
	email = new_email
	# Accounting for bbcode, we set it first, then trim the output
	sender_label.set_text(email.sender)
	sender_label.set_text(set_limited_text(sender_label.get_parsed_text()))
	subject_label.set_text(email.subject)
	subject_label.set_text(set_limited_text(subject_label.get_parsed_text(), 28))
	
	blurb_label.set_text(email.contents.split("\n")[0])
	blurb_label.text = set_limited_text(blurb_label.get_parsed_text())
	sender_dropdown.text = email.sender
	subject_dropdown.text = email.subject
	content.text = email.contents
	expand_panel.visible = false

func set_limited_text(input_text: String, limit: int = 16) -> String:
	if input_text.length() > limit:
		return input_text.substr(0, limit) + "..." 
	else:
		return input_text
	
