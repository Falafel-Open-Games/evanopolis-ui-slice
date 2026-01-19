extends Control

@onready var start_button: Button = %StartButton
const GAME_SCENE_PATH: String = "res://scenes/game.tscn"

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
