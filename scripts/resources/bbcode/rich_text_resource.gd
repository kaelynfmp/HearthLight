@tool

@icon("res://resources/resource-icons/item.svg")

extends RichTextEffect
class_name RichTextResource

## Syntax: [resource='Cotton']Cotton[/resource]

var bbtag:String = "resource"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var resource = char_fx.env.get("resource")
	var path = "res://resources/items/" + resource + ".tres"

	print(char_fx.get_relative_index())

	return true