class_name GameState
extends Node

var current_player_index: int
var player_positions: Array[int]
var tile_occupants: Array[Array]

signal player_changed(new_index: int)
signal player_position_changed(new_position: int, tile_slot: int)

func _ready() -> void:
	seed(GameConfig.game_id.hash())
	current_player_index = 0

func reset_positions() -> void:
	player_positions = []
	player_positions.resize(GameConfig.player_count)
	player_positions.fill(0) # all players starts at position 0
	
	tile_occupants = []
	tile_occupants.resize(GameConfig.board_size)
	for index in range(GameConfig.player_count): # tile of position 0 starts with one player index per slot
		tile_occupants[0].append(index)

func advance_turn() -> void:
	current_player_index = (current_player_index + 1) % GameConfig.player_count
	player_changed.emit(current_player_index)

func move_player(player_index: int, steps: int, board_size: int) -> void:
	assert(player_index >= 0 and player_index < player_positions.size())

	var current_tile: int = player_positions[player_index]
	var next_tile: int = (current_tile + steps) % board_size

	tile_occupants[current_tile].erase(player_index)
	tile_occupants[next_tile].append(player_index)
	player_positions[player_index] = next_tile
	
	var next_slot = tile_occupants[next_tile].size() - 1
	player_position_changed.emit(next_tile, next_slot)
