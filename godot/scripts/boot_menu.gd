extends Control

@onready var board_size_selector: OptionButton = %BoardSizeSelector
@onready var player_count_selector: OptionButton = %PlayerCountSelector
@onready var start_button: Button = %StartButton

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"
const BOARD_SIZES: Array[int] = [24, 30, 36]
const PLAYER_COUNTS: Array[int] = [2, 3, 4, 5, 6]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	_apply_board_size()
	_apply_player_count()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _apply_board_size() -> void:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null:
		return
	var selected_index: int = board_size_selector.selected
	var clamped_index: int = clamp(selected_index, 0, BOARD_SIZES.size() - 1)
	config.set("board_size", BOARD_SIZES[clamped_index])

func _apply_player_count() -> void:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null:
		return
	var selected_index: int = player_count_selector.selected
	var clamped_index: int = clamp(selected_index, 0, PLAYER_COUNTS.size() - 1)
	config.set("player_count", PLAYER_COUNTS[clamped_index])
