extends Control
## Страница настроек: локаль, скорость печати, автопролистывание.
##
## Значения читаются и сохраняются через автозагрузку GameSettings.

const BACK_SCENE := "res://scenes/main_menu.tscn"

@onready var title_label: Label = %Title
@onready var locale_label: Label = %LocaleLabel
@onready var locale_option: OptionButton = %LocaleOption
@onready var speed_label: Label = %SpeedLabel
@onready var speed_slider: HSlider = %SpeedSlider
@onready var speed_value: Label = %SpeedValue
@onready var auto_label: Label = %AutoLabel
@onready var auto_check: CheckButton = %AutoCheck
@onready var auto_ms_label: Label = %AutoMsLabel
@onready var auto_ms_slider: HSlider = %AutoMsSlider
@onready var auto_ms_value: Label = %AutoMsValue
@onready var back_button: Button = %BackButton

## Подавляет реакцию на изменения, пока UI заполняется из GameSettings.
var _updating := false


func _ready() -> void:
	_populate_locales()
	_connect_signals()
	_retranslate()
	_sync_from_settings()
	back_button.grab_focus()


func _populate_locales() -> void:
	locale_option.clear()
	for entry in GameSettings.LOCALES:
		locale_option.add_item(_locale_name(entry))


func _retranslate() -> void:
	title_label.text = tr("UI/Settings/Title")
	locale_label.text = tr("UI/Settings/Locale")
	speed_label.text = tr("UI/Settings/Speed")
	auto_label.text = tr("UI/Settings/Autoadvance")
	auto_check.text = tr("UI/Settings/AutoadvanceOn")
	auto_ms_label.text = tr("UI/Settings/AutoadvanceMs")
	back_button.text = tr("UI/Settings/Back")
	# Список локалей и подписи значений зависят от локали.
	var selected := locale_option.selected
	_populate_locales()
	locale_option.select(selected)
	_update_speed_label(speed_slider.value)
	_update_autoadvance_ms_label(auto_ms_slider.value)


## Человекочитаемое имя локали с учётом перевода.
func _locale_name(entry: Dictionary) -> String:
	if entry.code.is_empty():
		return tr("UI/Locale/System")
	return entry.name


func _connect_signals() -> void:
	locale_option.item_selected.connect(_on_locale_selected)
	speed_slider.value_changed.connect(_on_speed_changed)
	auto_check.toggled.connect(_on_autoadvance_toggled)
	auto_ms_slider.value_changed.connect(_on_autoadvance_ms_changed)
	back_button.pressed.connect(_on_back_pressed)
	GameSettings.locale_changed.connect(_on_locale_changed)


## Заполняет элементы управления текущими значениями.
func _sync_from_settings() -> void:
	_updating = true

	locale_option.select(GameSettings.get_locale_index())

	speed_slider.min_value = GameSettings.WPM_MIN
	speed_slider.max_value = GameSettings.WPM_MAX
	speed_slider.step = 10
	speed_slider.value = GameSettings.text_wpm
	_update_speed_label(GameSettings.text_wpm)

	auto_check.button_pressed = GameSettings.autoadvance
	auto_ms_slider.min_value = GameSettings.AUTO_MS_MIN
	auto_ms_slider.max_value = GameSettings.AUTO_MS_MAX
	auto_ms_slider.step = 1
	auto_ms_slider.value = GameSettings.autoadvance_ms
	_update_autoadvance_ms_label(GameSettings.autoadvance_ms)
	auto_ms_slider.editable = GameSettings.autoadvance

	_updating = false


func _on_locale_selected(index: int) -> void:
	if _updating:
		return
	GameSettings.set_locale_by_index(index)


func _on_locale_changed(_locale: String) -> void:
	_retranslate()


func _on_speed_changed(value: float) -> void:
	_update_speed_label(int(value))
	if _updating:
		return
	GameSettings.text_wpm = int(value)


func _on_autoadvance_toggled(pressed: bool) -> void:
	if _updating:
		return
	GameSettings.autoadvance = pressed
	auto_ms_slider.editable = pressed


func _on_autoadvance_ms_changed(value: float) -> void:
	_update_autoadvance_ms_label(int(value))
	if _updating:
		return
	GameSettings.autoadvance_ms = int(value)


func _update_speed_label(wpm: int) -> void:
	if wpm >= GameSettings.WPM_INSTANT:
		speed_value.text = tr("UI/Settings/Instant")
	else:
		speed_value.text = tr("UI/Settings/WpmUnit") % wpm


func _update_autoadvance_ms_label(ms: int) -> void:
	if ms <= GameSettings.AUTO_MS_INSTANT:
		auto_ms_value.text = tr("UI/Settings/Instant")
	else:
		auto_ms_value.text = tr("UI/Settings/MsUnit") % ms


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(BACK_SCENE)
