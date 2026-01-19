class_name GameState
extends Node

@export_range(2, 6, 1) var player_count: int = 6
@export_range(0, 5, 1) var current_player_index: int = 0:
	set(value):
		current_player_index = value
		player_changed.emit(current_player_index)

signal player_changed(new_index: int)

var player_positions: Array[int] = []
var tile_occupants: Dictionary = {}

func reset_positions() -> void:
	player_positions = []
	tile_occupants = {}
	for index in range(player_count):
		player_positions.append(0)
	tile_occupants[0] = []
	for index in range(player_count):
		tile_occupants[0].append(index)

func advance_turn() -> void:
	current_player_index = (current_player_index + 1) % player_count

func move_player(player_index: int, steps: int, board_size: int) -> Dictionary:
	var result: Dictionary = {}
	if player_index < 0 or player_index >= player_positions.size():
		return result

	var current_tile: int = player_positions[player_index]
	var next_tile: int = (current_tile + steps) % board_size

	if tile_occupants.has(current_tile):
		tile_occupants[current_tile].erase(player_index)

	if not tile_occupants.has(next_tile):
		tile_occupants[next_tile] = []
	tile_occupants[next_tile].append(player_index)
	player_positions[player_index] = next_tile

	result["tile_index"] = next_tile
	result["slot_index"] = tile_occupants[next_tile].size() - 1
	return result
