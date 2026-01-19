class_name GameState
extends Node

@export_range(2, 6, 1) var player_count: int = 6
@export_range(0, 5, 1) var current_player_index: int = 0:
	set(value):
		current_player_index = value
		player_changed.emit(current_player_index)

signal player_changed(new_index: int)

func advance_turn() -> void:
	current_player_index = (current_player_index + 1) % player_count
