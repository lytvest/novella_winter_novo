extends Control
## Главное меню визуальной новеллы.

const START_TIMELINE := "res://texts/chapter1.dtl"

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%LoadButton.pressed.connect(_on_load_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%StartButton.grab_focus()
	status_label.hide()


func _on_start_pressed() -> void:
	# TODO: заменить на выбор таймлайна, когда сюжет будет готов.
	if not ResourceLoader.exists(START_TIMELINE):
		_show_status("Таймлайн %s ещё не создан." % START_TIMELINE)
		return
	Dialogic.start(START_TIMELINE)


func _on_load_pressed() -> void:
	_show_status("Сохранения появятся позже.")


func _on_settings_pressed() -> void:
	_show_status("Настройки появятся позже.")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_status(text: String) -> void:
	status_label.text = text
	status_label.show()
