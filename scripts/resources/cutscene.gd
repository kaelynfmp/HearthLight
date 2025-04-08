class_name Cutscene
extends Resource

@export_multiline var text:Array[String]

@export var final_button_text:String

enum CUTSCENE_TYPE {
	AWAKEN, FREE_PLAY, MAIN_MENU
}

@export var cutscene_type:CUTSCENE_TYPE

var step:int = 0

func next_step() -> bool:
	if step < text.size() - 1:
		step += 1
		return true
	return false