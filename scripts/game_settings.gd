extends Node
## Глобальные пользовательские настройки новеллы.
##
## Хранит и применяет локаль, скорость печати текста и автопролистывание.
## Значения сохраняются средствами Dialogic (Dialogic.Settings -> global_info),
## поэтому доступны вне зависимости от слота сохранения.
##
## Доступ из кода: `GameSettings.text_wpm = 200` и т.п.

## Средняя длина слова для пересчёта WPM в скорость печати.
## Стандарт типографских тестов скорости чтения — 5 символов на слово.
const CHARS_PER_WORD := 5.0

## Диапазон скорости печати в словах в минуту.
## SPEED_MAX_WPM трактуется как «мгновенно» (текст появляется сразу).
const WPM_MIN := 50
const WPM_MAX := 500
const WPM_BASE := 150
## Значение WPM, при котором текст считается мгновенным.
const WPM_INSTANT := WPM_MAX

## Автопролистывание: задержка на символ (миллисекунды).
## Длинные тексты ждут дольше — задержка пропорциональна длине реплики.
const AUTO_MS_MIN := 0
const AUTO_MS_MAX := 200
const AUTO_MS_BASE := 40
## Задержка на символ, при которой автопролистывание срабатывает практически сразу.
const AUTO_MS_INSTANT := 0

## Поддерживаемые локали. Пустая строка — автоопределение системной локали.
const LOCALES := [
	{"code": "", "name": "Система / System"},
	{"code": "ru", "name": "Русский"},
	{"code": "en", "name": "English"},
]

## Сигналы для UI настроек.
signal text_wpm_changed(value: int)
signal autoadvance_changed(enabled: bool)
signal autoadvance_ms_changed(value: int)
signal locale_changed(locale: String)

## Скорость печати текста (слова в минуту). WPM_INSTANT — мгновенно.
var text_wpm: int = WPM_BASE:
	set(value):
		value = clampi(value, WPM_MIN, WPM_MAX)
		if text_wpm == value:
			return
		text_wpm = value
		_apply_text_speed()
		text_wpm_changed.emit(text_wpm)

## Автопролистывание: автоматический переход к следующей реплике.
var autoadvance: bool = false:
	set(value):
		if autoadvance == value:
			return
		autoadvance = value
		_apply_autoadvance()
		autoadvance_changed.emit(autoadvance)

## Задержка автопролистывания в миллисекундах на символ.
var autoadvance_ms: int = AUTO_MS_BASE:
	set(value):
		value = clampi(value, AUTO_MS_MIN, AUTO_MS_MAX)
		if autoadvance_ms == value:
			return
		autoadvance_ms = value
		_apply_autoadvance_ms()
		autoadvance_ms_changed.emit(autoadvance_ms)

## Код текущей локали ("" — системная).
var locale: String = "":
	set(value):
		if locale == value:
			return
		locale = value
		_apply_locale()
		locale_changed.emit(locale)


func _ready() -> void:
	# Гарантируем существование файла global_info: иначе Dialogic не сохранит настройки.
	if Dialogic.has_subsystem("Save"):
		Dialogic.Save._make_sure_slot_dir_exists()
	_load()
	# Применяем ко всему, что уже могло подняться раньше (Dialogic автозагрузкой выше).
	_apply_all()


#region ПРЕОБРАЗОВАНИЯ
################################################################################

## Переводит скорость печати (WPM) в секунды на символ.
## WPM_INSTANT (и выше) дают 0 — мгновенный текст.
func wpm_to_letter_speed(wpm: int) -> float:
	if wpm >= WPM_INSTANT:
		return 0.0
	return 60.0 / (float(wpm) * CHARS_PER_WORD)


## Переводит секунды на символ обратно в WPM (для синхронизации).
func letter_speed_to_wpm(letter_speed: float) -> int:
	if letter_speed <= 0.0:
		return WPM_INSTANT
	return int(round(60.0 / (letter_speed * CHARS_PER_WORD)))


## Текущая скорость печати в секундах на символ.
func get_letter_speed() -> float:
	return wpm_to_letter_speed(text_wpm)


## Возвращает человекочитаемое имя текущей локали для UI.
func get_locale_name() -> String:
	for entry in LOCALES:
		if entry.code == locale:
			return entry.name
	return locale


## Применяет настройку локали к TranslationServer.
func set_locale_by_index(index: int) -> void:
	if index < 0 or index >= LOCALES.size():
		return
	locale = LOCALES[index].code


## Индекс текущей локали в списке LOCALES (для OptionButton).
func get_locale_index() -> int:
	for i in LOCALES.size():
		if LOCALES[i].code == locale:
			return i
	return 0

#endregion


#region ВНУТРЕННЕЕ
################################################################################

func _load() -> void:
	text_wpm = int(Dialogic.Settings.get_setting("text_wpm", WPM_BASE))
	autoadvance = Dialogic.Settings.get_setting("autoadvance_enabled", false)
	autoadvance_ms = int(Dialogic.Settings.get_setting("autoadvance_ms", AUTO_MS_BASE))
	locale = Dialogic.Settings.get_setting("locale", "")


func _apply_all() -> void:
	_apply_text_speed()
	_apply_autoadvance()
	_apply_autoadvance_ms()
	_apply_locale()


func _apply_text_speed() -> void:
	# Сохраняем WPM для персистентности.
	Dialogic.Settings.set("text_wpm", text_wpm)
	# Dialogic трактует user_speed как МНОЖИТЕЛЬ базовой скорости проекта
	# (см. ModuleText.update_text_speed: letter_speed * speed_multiplier * user_speed),
	# поэтому переводим целевые секунды на символ в множитель.
	var base_letter_speed: float = ProjectSettings.get_setting("dialogic/text/letter_speed", 0.01)
	var target := get_letter_speed()
	var multiplier := 0.0 if base_letter_speed <= 0.0 else target / base_letter_speed
	Dialogic.Settings.set("text_speed", multiplier)


func _apply_autoadvance() -> void:
	# Храним настройку в Dialogic для персистентности...
	Dialogic.Settings.set("autoadvance_enabled", autoadvance)
	# ...и применяем к живому объекту автопролистывания.
	var aa = _get_auto_advance()
	if aa:
		aa.enabled_forced = autoadvance


func _apply_autoadvance_ms() -> void:
	Dialogic.Settings.set("autoadvance_ms", autoadvance_ms)
	# Dialogic измеряет задержку автопролистывания в секундах на символ.
	var seconds_per_char := float(autoadvance_ms) / 1000.0
	var aa = _get_auto_advance()
	if aa:
		# Задержка пропорциональна длине текста: длинные реплики ждут дольше.
		aa.per_character_delay = seconds_per_char
		aa.per_word_delay = 0.0
		# Фиксированную задержку не используем — она не зависит от длины текста.
		aa.fixed_delay = 0.0


## Возвращает объект автопролистывания Dialogic (или null, если подсистема недоступна).
func _get_auto_advance():
	if Dialogic.has_subsystem("Inputs"):
		return Dialogic.Inputs.auto_advance
	return null


func _apply_locale() -> void:
	# Сохраняем локаль в настройках Dialogic и применяем к TranslationServer.
	Dialogic.Settings.set("locale", locale)
	if locale.is_empty():
		TranslationServer.set_locale(OS.get_locale())
	else:
		TranslationServer.set_locale(locale)

#endregion
