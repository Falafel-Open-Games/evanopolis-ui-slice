class_name GameState
extends Node

const SIDE_COUNT: int = 6
const CITY_BASE_PRICE: Dictionary = {
	"Caracas": 1.0,
	"Assuncion": 2.0,
	"Ciudad del Este": 2.0,
	"Minsk": 3.0,
	"Irkutsk": 3.0,
	"Rockdale": 4.0,
}
const SPECIAL_PROPERTIES: Array[Dictionary] = [
	{"name": "Importadora 1", "price": 5.0},
	{"name": "Subestacao 1", "price": 6.0},
	{"name": "Oficina Propria", "price": 8.0},
	{"name": "Importadora 2", "price": 5.0},
	{"name": "Subestacao 2", "price": 6.0},
	{"name": "Cooling Plant", "price": 10.0},
]

var current_player_index: int
var player_positions: Array[int]
var tiles: Array[TileInfo]
var balances: Array[float] = []

signal player_changed(new_index: int)
signal player_position_changed(new_position: int, tile_slot: int)
signal balance_changed(player_index: int, new_balance: float)

func _ready() -> void:
	seed(GameConfig.game_id.hash())
	current_player_index = 0
	_build_tile_info()

func reset_positions() -> void:
	assert(not tiles.is_empty())
	assert(tiles.size() == GameConfig.board_size)
	player_positions = []
	player_positions.resize(GameConfig.player_count)
	player_positions.fill(0) # all players starts at position 0

	balances = []
	balances.resize(GameConfig.player_count)
	for index in range(GameConfig.player_count):
		balances[index] = GameConfig.starting_balance
		balance_changed.emit(index, balances[index])

	# Clear stale occupants from previous runs before seeding start tile.
	for tile_index in range(tiles.size()):
		tiles[tile_index].occupants = []
		tiles[tile_index].owner_index = -1
	# tile of position 0 starts with one player index per slot
	for index in range(GameConfig.player_count):
		tiles[0].occupants.append(index)

func advance_turn() -> void:
	current_player_index = (current_player_index + 1) % GameConfig.player_count
	player_changed.emit(current_player_index)

func move_player(player_index: int, steps: int, board_size: int) -> void:
	assert(player_index >= 0 and player_index < player_positions.size())

	var current_tile: int = player_positions[player_index]
	var next_tile: int = (current_tile + steps) % board_size

	var current_occupants: Array[int] = tiles[current_tile].occupants
	var next_occupants: Array[int] = tiles[next_tile].occupants
	current_occupants.erase(player_index)
	next_occupants.append(player_index)
	player_positions[player_index] = next_tile
	
	var next_slot: int = next_occupants.size() - 1
	player_position_changed.emit(next_tile, next_slot)

func get_tile_info(tile_index: int) -> TileInfo:
	assert(not tiles.is_empty())
	assert(tile_index >= 0 and tile_index < tiles.size())
	return tiles[tile_index]

func get_player_balance(player_index: int) -> float:
	assert(player_index >= 0 and player_index < balances.size())
	return balances[player_index]

func purchase_tile(player_index: int, tile_index: int) -> bool:
	assert(player_index >= 0 and player_index < balances.size())
	assert(tile_index >= 0 and tile_index < tiles.size())
	var tile: TileInfo = tiles[tile_index]
	if not _is_tile_buyable(tile):
		return false
	var price: float = _get_tile_price(tile)
	if price <= 0.0:
		return false
	if balances[player_index] < price:
		return false
	balances[player_index] -= price
	balance_changed.emit(player_index, balances[player_index])
	tile.owner_index = player_index
	return true

func _build_tile_info() -> void:
	tiles = []
	tiles.resize(GameConfig.board_size)
	var tiles_per_side: int = _get_tiles_per_side()

	for tile_index in range(GameConfig.board_size):
		var info: TileInfo = TileInfo.new()

		@warning_ignore("integer_division")
		var side_index: int = tile_index / tiles_per_side
		var side_slot: int = tile_index % tiles_per_side

		if side_slot == 0:
			match side_index:
				0:
					info.tile_type = "start"
				3:
					info.tile_type = "inspection"
				1, 2, 4, 5:
					info.tile_type = "incident"
					info.incident_kind = _incident_kind_for_side(side_index)
		elif side_slot == 1:
			info.tile_type = "special_property"
			var special_index: int = side_index
			if special_index >= 0 and special_index < SPECIAL_PROPERTIES.size():
				info.special_property_name = SPECIAL_PROPERTIES[special_index]["name"]
				info.special_property_price = SPECIAL_PROPERTIES[special_index]["price"]
		else:
			info.tile_type = "property"
			info.city = _city_for_side(side_index)
			info.property_price = CITY_BASE_PRICE.get(info.city, 0.0)

		tiles[tile_index] = info

func _get_tile_price(tile: TileInfo) -> float:
	if tile.tile_type == "property":
		return tile.property_price
	if tile.tile_type == "special_property":
		return tile.special_property_price
	return 0.0

func _is_tile_buyable(tile: TileInfo) -> bool:
	return (
		(tile.tile_type == "property" or tile.tile_type == "special_property")
		and tile.owner_index == -1
	)

func _get_tiles_per_side() -> int:
	assert(GameConfig.board_size % SIDE_COUNT == 0)
	@warning_ignore("integer_division")
	return GameConfig.board_size / SIDE_COUNT

func _incident_kind_for_side(side_index: int) -> String:
	match side_index:
		1, 4:
			return "suerte"
		2, 5:
			return "destino"
	return ""

func _city_for_side(side_index: int) -> String:
	assert(side_index >= 0 and side_index < Palette.CITY_ORDER.size())
	return Palette.CITY_ORDER[side_index]
