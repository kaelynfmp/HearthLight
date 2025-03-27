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
	sender_label.finished.connect(_finished.bind(email.sender, sender_label))
	subject_label.finished.connect(_finished.bind(email.subject, subject_label))
	blurb_label.finished.connect(_finished.bind(email.contents.split("\n")[0], blurb_label))
	
	sender_dropdown.finished.connect(_finished.bind(email.sender, sender_dropdown))
	subject_dropdown.finished.connect(_finished.bind(email.subject, subject_dropdown))
	
	content.text = email.contents
	expand_panel.visible = false

func _finished(_text:String, label:RichTextLabel):
	if !label.initialized:
		label.initialized = true
		Utility.set_truncated_text(_text, label)
		
	
