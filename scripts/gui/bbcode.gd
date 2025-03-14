@tool

extends RichTextLabel

@export var insert_image_width:int = 30 # In pixels
var tooltip_appeared = false
var initialized:bool = false

var tooltip_node:PanelContainer

func _ready():
	meta_underlined = false
	hint_underlined = false
	meta_clicked.connect(_meta_clicked)
	
func _make_custom_tooltip(for_text: String) -> Object:
	if for_text != "":
		var tooltip = load("res://scenes/tooltip.tscn").instantiate()
		tooltip.set_modulate(Color(1, 1, 1, 1))
		tooltip_node = tooltip.find_child("TooltipContainer")
		tooltip.remove_child(tooltip_node)
		tooltip_node.set_owner(null)
		
		var tooltip_text = tooltip_node.find_child("Tooltip", true)
		var tooltip_title = tooltip_node.find_child("Title", true)
		tooltip_text.text = ""
		tooltip_title.text = for_text
		if for_text in Utility.items:
			var item:Item = Utility.items[for_text]
			tooltip_text.text = item.description
		if for_text in Utility.gadgets:
			var gadget:Gadget = Utility.gadgets[for_text]
			tooltip_text.text = gadget.description
		
		return tooltip_node
	var label = Label.new()
	label.visible = false
	return label

func _process(delta: float):
	if tooltip_node != null:
		var popup:PopupPanel = tooltip_node.get_parent()
		var stylebox:StyleBoxEmpty = StyleBoxEmpty.new()
		stylebox.set_content_margin_all(12.0)
		popup.add_theme_stylebox_override("panel", stylebox)
	else:
		tooltip_appeared = false
	
func _meta_clicked(meta: Variant):
	print("test")

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
		var text_start_pos = next_tag_pos + opener_str.length() + resource_name.length() + 1
		var text_value = value.substr(text_start_pos, closing_tag_pos - text_start_pos)
	
		if resource_name in Utility.items:
			var token:String = ""
			var item = Utility.items[resource_name]
			token += "[hint=" + resource_name + "][b]"
			if item.texture != null:
				var texture_path:String = item.texture.resource_path
				token += "[img width=" + str(insert_image_width) + "px,center]"
				token += texture_path
				token += "[/img]"
			token += text_value
			token += "[/b][/hint]"
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
