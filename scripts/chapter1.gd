extends Node2D
## Сцена первой главы. При входе запускает таймлайн Dialogic.

const CHAPTER_TIMELINE := "res://texts/chapter1.dtl"


func _ready() -> void:
	Dialogic.start(CHAPTER_TIMELINE)
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_timeline_ended() -> void:
	# Позже здесь будет переход к главе 2 или в меню.
	print("[Chapter1] Таймлайн завершён.")
