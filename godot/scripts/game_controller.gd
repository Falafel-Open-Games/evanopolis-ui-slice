extends Node

@onready var game_state: GameState = %GameState
@onready var right_sidebar: RightSidebar = %RightSidebar

func _ready() -> void:

	if game_state != null:
		game_state.player_changed.connect(_on_player_changed)
		_on_player_changed(game_state.current_player_index)

	call_deferred("_bind_sidebar")

func _bind_sidebar() -> void:
	if right_sidebar == null:
		return
	if right_sidebar.end_turn_button == null:
		return
	if not right_sidebar.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		right_sidebar.end_turn_button.pressed.connect(_on_end_turn_pressed)

func _on_end_turn_pressed() -> void:
	if game_state == null:
		return
	game_state.advance_turn()

func _on_player_changed(new_index: int) -> void:
	if right_sidebar == null:
		return
	right_sidebar.set_current_player(new_index)
