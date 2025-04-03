extends Node

## The synchronized stream of all gadgets above the primitive age
var gadget_audio:AudioStreamPlayer2D
## A dictionary that connects a gadget to it's audio index in the synchronized stream
var gadget_audio_index:Dictionary[Gadget, int] # Populate dict once ready

var playback:AudioStreamPlaybackPolyphonic

var active_gadgets:Dictionary[String, Dictionary] = {
	"c grinder.wav": {},
	"c loom.wav": {},
	"c plant.wav": {},
	"c sieve.wav": {},
	"c stove.wav": {},
	"c generator.wav": {},
	"e grinder.wav": {},
	"e loom.wav": {},
	"e plant.wav": {},
	"e sieve.wav": {},
	"e stove.wav": {},
	"e generator.wav": {}
}

## Enum of all possible button sounds
enum BUTTON {LOWER, BUTTON_CLICK, SELECT, DOUBLE_CLICK, HIGH_SELECT, DOUBLE_CLICK_TWO, HIGHLIGHT, CLICK, PICK_UP, PUT_DOWN, BUY, NO_MONEY, REWARD, CONFIRM, SHORT_CLICK}

var button_sounds:Array[AudioStream] = [
	preload("res://resources/audio/UI Sounds/UI 2.1 (lower button).mp3"),
	preload("res://resources/audio/UI Sounds/UI 2 (button click).mp3"),
	preload("res://resources/audio/UI Sounds/UI 3 (select).mp3"),
	preload("res://resources/audio/UI Sounds/UI 4 (Double Click).mp3"),
	preload("res://resources/audio/UI Sounds/UI 6 (high select).mp3"),
	preload("res://resources/audio/UI Sounds/UI 8 (double click 2).mp3"),
	preload("res://resources/audio/UI Sounds/UI 1 (highlight).mp3"),
	preload("res://resources/audio/UI Sounds/UI 9 (click).wav"),
	preload("res://resources/audio/UI Sounds/UI 11 (pick up).wav"),
	preload("res://resources/audio/UI Sounds/UI 11.1 (put down).wav"),
	preload("res://resources/audio/Money/buy 2.mp3"),
	preload("res://resources/audio/UI Sounds/UI 10 (close).wav"),
	preload("res://resources/audio/Money/earned money 1.mp3"),
	preload("res://resources/audio/UI Sounds/UI 12 (confirm).wav"),
	preload("res://resources/audio/UI Sounds/UI 13 (short click).wav")
	]


func set_gadget_audio(stream_player:AudioStreamPlayer2D):
	gadget_audio = stream_player

# https://forum.godotengine.org/t/best-proper-way-to-do-ui-sounds-hover-click/39081/3	

func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)

	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()

	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node:Node) -> void:
	if node is Button or node is TextureButton:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.pressed.connect(_play_pressed.bind(node))
	
func _play_pressed(node:Node) -> void:
	if "button_sound" in node and node.button_sound != null:
		play_button_sound(node.button_sound)
		
func play_button_sound(index:int, db:float=0, pitch:float=1, pitch_range:float=0.1):
	playback.play_stream(button_sounds[index], 0, db, randf_range(pitch - pitch_range, pitch + pitch_range))

	
func _process(_delta: float) -> void:
	for audio_string:String in active_gadgets:
		var gadgets_count = active_gadgets[audio_string].size()
		if gadgets_count > 0:
			pass
		