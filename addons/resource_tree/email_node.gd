@tool
extends GraphNode

@onready var email_node:EmailEditorNode
signal moved(to:Vector2, recipe_node:RecipeEditorNode)
signal kill(node:GraphNode)

func _process(_delta: float) -> void:
	if email_node == null or email_node.email == null:
		return
	var email:Email = email_node.email
	var container:Control = find_child("EmailContainer")
	var panel:Panel = container.find_child("Panel")
	if container != null:
		var sender_label:RichTextLabel = container.find_child("Sender")
		Utility.set_truncated_text(email.sender, sender_label)
		var subject_label:RichTextLabel = container.find_child("Subject")
		Utility.set_truncated_text(email.subject, subject_label)
		var blurb_label:RichTextLabel = container.find_child("Blurb")
		Utility.set_truncated_text(email.contents.split("\n")[0], blurb_label)
		
		
		var content_label:RichTextLabel = panel.find_child("Content")
		content_label.text = email.contents
		var sender_dropdown_label:RichTextLabel = panel.find_child("SenderDropdown")
		Utility.set_truncated_text(email.sender, sender_dropdown_label)
		var subject_dropdown_label:RichTextLabel = panel.find_child("SubjectDropdown")
		Utility.set_truncated_text(email.subject, subject_dropdown_label)

func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, email_node)

func _on_delete_button_pressed() -> void:
	kill.emit(self)
	var dir: DirAccess = DirAccess.open("res://resources/emails")
	dir.remove(email_node.email.get_path())
	moved.emit(Vector2.ZERO, email_node) # Sends the move signal to tell the recipe tree immediately to check if it is alive
	EditorInterface.get_resource_filesystem().scan()

func _on_node_selected() -> void:
	EditorInterface.edit_resource(email_node.email)