@tool

extends RichTextLabel

@export var insert_image_width:int = 30 # In pixels
var tooltip_appeared = false
var initialized:bool = false

var tooltip_node:Control

func _ready():
	meta_underlined = false
	hint_underlined = false
	meta_clicked.connect(_meta_clicked)
	
func _make_custom_tooltip(for_text: String) -> Object:
	if for_text != "":
		tooltip_node = load("res://scenes/tooltip.tscn").instantiate()
		tooltip_node.set_modulate(Color(1, 1, 1, 1))
		var tooltip_container:PanelContainer = tooltip_node.find_child("TooltipContainer")
		
		var tooltip_image:TextureRect = tooltip_container.find_child("TooltipImage", true)
		var tooltip_text_label:RichTextLabel = tooltip_container.find_child("Tooltip", true)
		var tooltip_title:RichTextLabel = tooltip_container.find_child("Title", true)
		tooltip_text_label.text = for_text
		tooltip_title.text = ""
		if for_text in Utility.items:
			var item:Item = Utility.items[for_text]
			tooltip_image.texture = item.texture
			tooltip_text_label.text = item.description
			tooltip_title.text = item.name
		if for_text in Utility.gadgets:
			var gadget:Gadget = Utility.gadgets[for_text]
			tooltip_image.texture = gadget.item.texture
			tooltip_text_label.text = gadget.description
			tooltip_title.text = gadget.name
			
		tooltip_node.set_scale(Vector2(0.5, 0.5))
		return tooltip_node
	var label = Label.new()
	label.visible = false
	return label

func _process(delta: float):
	if tooltip_node != null:
		var popup:PopupPanel = tooltip_node.get_parent()
		var stylebox:StyleBoxFlat = StyleBoxFlat.new()
		tooltip_node.set_custom_minimum_size(tooltip_node.find_child("TooltipContainer").get_minimum_size()/2 + Vector2(6.0, 6.0))
		stylebox.set_content_margin_all(6.0)
		stylebox.set_bg_color(Color.hex(0x99999900))
		if popup != null:
			popup.add_theme_stylebox_override("panel", stylebox)
	else:
		tooltip_appeared = false
	
func _meta_clicked(meta: Variant):
	if Engine.is_editor_hint():
		if meta in Utility.items:
			EditorInterface.edit_resource(Utility.items[meta])
		if meta in Utility.gadgets:
			EditorInterface.edit_resource(Utility.gadgets[meta])
	elif meta == "Botsy":
		GameManager.navigate_to_botsy()

func set_text_with_bbcode(value: String):
	text = ""
	var tokens:Array[String] = []
	var pos:int = 0
	while pos < value.length():
		var type:String = "res"
		var opener_str:String = "[" + type + "="
		var closer_str:String = "[/" + type + "]"
		var next_tag_pos:int = value.find(opener_str, pos)
		if next_tag_pos == -1:
			tokens.append(value.substr(pos, value.length() - pos))
			break
		
		if next_tag_pos > pos:
			# Add text up to this point
			tokens.append(value.substr(pos, next_tag_pos - pos))
		
		var valid_ending:bool = true
		var end_tag_pos:int = value.find("]", next_tag_pos)
		if end_tag_pos == -1:
			# Doesn't have a proper ending, so go past
			valid_ending = false
	
		var closing_tag_pos:int = value.find(closer_str, next_tag_pos)
		if closing_tag_pos == -1:
			# Doesn't have a proper ending, so go past
			valid_ending = false
		
		if closing_tag_pos < end_tag_pos:
			# If the closing tag appears before the ending tag
			# Doesn't have a proper ending, so go past
			valid_ending = false
			
		if !valid_ending:
			tokens.append(opener_str)
			pos = next_tag_pos + opener_str.length()
			continue
		
		var resource_name:String = value.substr(next_tag_pos + opener_str.length(), end_tag_pos - next_tag_pos - opener_str.length())
		var text_start_pos:int = next_tag_pos + opener_str.length() + resource_name.length() + 1
		var text_value:String = value.substr(text_start_pos, closing_tag_pos - text_start_pos)
	
		if resource_name == "Botsy":
			var token:String = ""
			token += "[url=Botsy]"
			token += "[u]"
			# INSERT TEXTURE LATER
			token += text_value
			token += "[/u]"
			token += "[/url]"
			tokens.append(token)
		elif resource_name in Utility.items:
			var token:String = ""
			var item = Utility.items[resource_name]
			token += "[hint=" + resource_name + "]"
			if Engine.is_editor_hint(): token += "[url=" + resource_name + "]"
			token += "[b]"
			if item.texture != null:
				var texture_path:String = item.texture.resource_path
				token += "[img width=" + str(insert_image_width) + "px,center]"
				token += texture_path
				token += "[/img]"
			token += text_value
			token += "[/b]"
			if Engine.is_editor_hint(): token += "[/url]"
			token += "[/hint]"
			tokens.append(token)
		elif resource_name in Utility.gadgets:
			var token:String = ""
			var gadget = Utility.gadgets[resource_name]
			token += "[hint=" + resource_name + "]"
			if Engine.is_editor_hint(): token += "[url=" + resource_name + "]"
			token += "[b]"
			if gadget.texture != null:
				var texture_path:String = gadget.texture.resource_path
				token += "[img width=" + str(insert_image_width) + "px,center]"
				token += texture_path
				token += "[/img]"
			token += text_value
			token += "[/b]"
			if Engine.is_editor_hint(): token += "[/url]"
			token += "[/hint]"
			tokens.append(token)
		else:
			tokens.append(value.substr(next_tag_pos, closing_tag_pos + closer_str.length() - next_tag_pos)) 
		
		pos = closing_tag_pos + closer_str.length()
		
	for token in tokens:
		text += token

func _set(property: StringName, value: Variant) -> bool:
	if property == "text":
		set_text_with_bbcode(value)
		return true
	return false
