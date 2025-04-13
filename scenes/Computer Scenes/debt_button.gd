extends Button

func _physics_process(_delta: float):
	disabled = GameManager.currency < GameManager.debt and not GameManager.is_debugging

func _pressed() -> void:
	GameManager.pay_debt()
