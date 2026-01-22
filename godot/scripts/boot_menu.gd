extends Control

@onready var board_size_selector: OptionButton = %BoardSizeSelector
@onready var player_count_selector: OptionButton = %PlayerCountSelector
@onready var turn_time_selector: OptionButton = %TurnTimeSelector
@onready var game_id_input: LineEdit = %GameIdInput
@onready var start_button: Button = %StartButton
@onready var subtitle: Label = %Subtitle

@export var game_scene_path: PackedScene

const BOARD_SIZES: Array[int] = [24, 30, 36]
const PLAYER_COUNTS: Array[int] = [2, 3, 4, 5, 6]
const TURN_DURATIONS: Array[int] = [10, 30, 60]

func _ready() -> void:
	game_id_input.text = Crypto.new().generate_random_bytes(5).hex_encode()
	start_button.pressed.connect(_on_start_pressed)
	subtitle.text = "Offline prototype (build %s)" % [GameConfig.build_id]

func _on_start_pressed() -> void:
	GameConfig.board_size = BOARD_SIZES[board_size_selector.selected]
	GameConfig.player_count = PLAYER_COUNTS[player_count_selector.selected]
	GameConfig.turn_duration = TURN_DURATIONS[turn_time_selector.selected]
	GameConfig.game_id = game_id_input.text.strip_edges()
	get_tree().change_scene_to_packed(game_scene_path)
