extends Node

signal inventory_changed

@export var inventory:bool = false

var cursor:Node2D

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		change_inventory()

func change_inventory():
	inventory = !inventory
	inventory_changed.emit()

func set_cursor(setting_cursor: Node2D):
	cursor = setting_cursor
	
func get_cursor():
	return cursor