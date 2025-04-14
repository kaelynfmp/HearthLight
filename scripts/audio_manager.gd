extends Node

## The synchronized stream of all gadgets above the primitive age
var gadget_audio:AudioStreamPlayer2D
## A dictionary that connects a gadget to it's audio index in the synchronized stream
var gadget_audio_index:Dictionary[Gadget, int] # Populate dict once ready

var playback:AudioStreamPlaybackPolyphonic

var teleport_player:AudioStreamPlayer
var ambient_audio: AudioStreamPlayer2D
var intro_ambient_audio: AudioStreamPlayer2D
var rain_audio: AudioStreamPlayer2D
var already_stop: bool = false
var good_ending_audio: AudioStreamPlayer2D

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
	"e generator.wav": {},
	"teleporter loop.wav": {}
}

var sync_stream_indexes:Dictionary[String, int] = {
	"c grinder.wav": -1,
	"c loom.wav": -1,
	"c plant.wav": -1,
	"c sieve.wav": -1,
	"c stove.wav": -1,
	"c generator.wav": -1,
	"e grinder.wav": -1,
	"e loom.wav": -1,
	"e plant.wav": -1,
	"e sieve.wav": -1,
	"e stove.wav": -1,
	"e generator.wav": -1,
	"teleporter loop.wav": -1
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

var teleport_sound:AudioStream = preload("res://resources/audio/Gadgets/teleporter single.wav")

func set_ambient_audio(stream_player:AudioStreamPlayer2D):
	ambient_audio = stream_player
	
func set_intro_ambient_audio(stream_player:AudioStreamPlayer2D):
	intro_ambient_audio = stream_player
	
func set_good_ending_audio(stream_player:AudioStreamPlayer2D):
	good_ending_audio = stream_player

func set_gadget_audio(stream_player:AudioStreamPlayer2D):
	gadget_audio = stream_player
	for index in range(stream_player.stream.stream_count):
		var sync_stream = stream_player.stream.get_sync_stream(index)
		for audio_string:String in active_gadgets:
			if sync_stream.resource_path == "res://resources/audio/Gadgets/" + audio_string:
				sync_stream_indexes[audio_string] = index
				break

# https://forum.godotengine.org/t/best-proper-way-to-do-ui-sounds-hover-click/39081/3	

func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)
	rain_audio = AudioStreamPlayer2D.new()
	add_child(rain_audio)
	
	rain_audio.stream = load("res://resources/audio/Background Rain.mp3")
	rain_audio.volume_db = -6.0
	rain_audio.play()
	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()
	get_tree().node_added.connect(_on_node_added)
	
	# Have an inaudible teleport player that is actually just signalling the loop to be active
	# This ensures the teleport sounds are longer than 0 seconds, since teleports are instant
	teleport_player = AudioStreamPlayer.new()
	teleport_player.set_volume_db(-60) # Make it quiet
	add_child(teleport_player)
	
	teleport_player.stream = teleport_sound

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
	
func remove_audio(audio_string, key):
	active_gadgets[audio_string].erase(key)

func _process(_delta: float) -> void:
	if gadget_audio != null:
		for audio_string:String in active_gadgets:
			if audio_string == "teleporter loop.wav":
				if teleport_player.playing:
					# If the teleport noise is playing, again, since teleports are instant
					gadget_audio.stream.set_sync_stream_volume(sync_stream_indexes[audio_string], 0.0)
				else:
					gadget_audio.stream.set_sync_stream_volume(sync_stream_indexes[audio_string], -60.0)
			else:
				var gadgets_count = active_gadgets[audio_string].size()
				if gadgets_count > 0 and not GameManager.sleeping:
					gadget_audio.stream.set_sync_stream_volume(sync_stream_indexes[audio_string], 0.0)
				else:
					gadget_audio.stream.set_sync_stream_volume(sync_stream_indexes[audio_string], -60.0)
		

func play_teleport_noise(): # Re-up teleport noise
	teleport_player.play()
	

func transition_good_ending():
	if intro_ambient_audio.playing:
		intro_ambient_audio.stop()
	if ambient_audio.playing:
		ambient_audio.loop = false
		ambient_audio.stop()
	playback.play_stream(load("res://resources/audio/explosion.wav"), 0, -6)
	good_ending_audio.play()
	#good_ending_audio.finished.connect(restart_ambient)
	
func transition_free_play():
	good_ending_audio.stop()
	restart_ambient()
	
func restart_ambient():
	ambient_audio.seek(0)
	ambient_audio.loop = true
	ambient_audio.play()

func stop_intro():
	if not already_stop:
		already_stop = true
		intro_ambient_audio.stop()
		intro_ambient_audio.stream = load("res://resources/audio/intro transition.wav")
		intro_ambient_audio.loop = false
		intro_ambient_audio.play()
		intro_ambient_audio.autoplay = false
		intro_ambient_audio.finished.connect(reset_audio)

func reset_audio():
	ambient_audio.seek(0)
	ambient_audio.play()
	gadget_audio.seek(0)
