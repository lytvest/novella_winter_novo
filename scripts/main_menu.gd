extends Control
## Главное меню визуальной новеллы.

const START_TIMELINE := "res://texts/chapter1.dtl"
const SETTINGS_SCENE := "res://scenes/settings.tscn"

const LOCALE_CHANGED_STATUS := "UI/Menu/StatusLoad"
const STATUS_NO_TIMELINE := "UI/Menu/StatusNoTimeline"

@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var load_button: Button = %LoadButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var title_label: Label = %Title


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	status_label.hide()

	GameSettings.locale_changed.connect(_on_locale_changed)
	_retranslate()


## Обновляет все подписи под текущую локаль.
func _retranslate() -> void:
	title_label.text = tr("UI/Menu/Title")
	start_button.text = tr("UI/Menu/Start")
	load_button.text = tr("UI/Menu/Load")
	settings_button.text = tr("UI/Menu/Settings")
	quit_button.text = tr("UI/Menu/Quit")


func _on_start_pressed() -> void:
	# TODO: заменить на выбор таймлайна, когда сюжет будет готов.
	if not ResourceLoader.exists(START_TIMELINE):
		_show_status(tr(STATUS_NO_TIMELINE) % START_TIMELINE)
		return
	Dialogic.start(START_TIMELINE)


func _on_load_pressed() -> void:
	_show_status(tr(LOCALE_CHANGED_STATUS))


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_locale_changed(_locale: String) -> void:
	_retranslate()


func _show_status(text: String) -> void:
	status_label.text = text
	status_label.show()
