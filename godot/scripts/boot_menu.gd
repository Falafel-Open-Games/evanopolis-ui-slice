extends Control

@onready var board_size_selector: OptionButton = %BoardSizeSelector
@onready var player_count_selector: OptionButton = %PlayerCountSelector
@onready var turn_time_selector: OptionButton = %TurnTimeSelector
@onready var game_id_input: LineEdit = %GameIdInput
@onready var start_button: Button = %StartButton

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"
const BOARD_SIZES: Array[int] = [24, 30, 36]
const PLAYER_COUNTS: Array[int] = [2, 3, 4, 5, 6]
const TURN_DURATIONS: Array[int] = [10, 30, 60]

func _ready() -> void:
	_seed_game_id_input()
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	_apply_board_size()
	_apply_player_count()
	_apply_turn_duration()
	_apply_game_id()
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

func _apply_turn_duration() -> void:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null:
		return
	var selected_index: int = turn_time_selector.selected
	var clamped_index: int = clamp(selected_index, 0, TURN_DURATIONS.size() - 1)
	config.set("turn_duration", TURN_DURATIONS[clamped_index])

func _seed_game_id_input() -> void:
	if game_id_input == null:
		return
	if not game_id_input.text.is_empty():
		return
	game_id_input.text = _generate_game_id()

func _apply_game_id() -> void:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null or game_id_input == null:
		return
	var game_id: String = game_id_input.text.strip_edges()
	if game_id.is_empty():
		game_id = _generate_game_id()
		game_id_input.text = game_id
	config.set("game_id", game_id)

func _generate_game_id() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var timestamp: int = int(Time.get_unix_time_from_system())
	var salt: int = rng.randi_range(1000, 9999)
	return "%d-%d" % [timestamp, salt]
