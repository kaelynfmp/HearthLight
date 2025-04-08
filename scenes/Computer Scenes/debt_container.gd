extends HBoxContainer

func _ready() -> void:
	GameManager.paid_off_debt.connect(hide)