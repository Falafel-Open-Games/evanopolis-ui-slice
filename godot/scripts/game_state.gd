class_name GameState
extends Node

const SIDE_COUNT: int = 6
const CITY_BASE_PRICE: Dictionary = {
	"Caracas": 20000.0,
	"Assuncion": 50000.0,
	"Ciudad del Este": 80000.0,
	"Minsk": 110000.0,
	"Irkutsk": 150000.0,
	"Rockdale": 200000.0,
}
const SPECIAL_PROPERTIES: Array[Dictionary] = [
	{"name": "Importadora 1", "price": 5.0},
	{"name": "Subestacao 1", "price": 6.0},
	{"name": "Oficina Propria", "price": 8.0},
	{"name": "Importadora 2", "price": 5.0},
	{"name": "Subestacao 2", "price": 6.0},
	{"name": "Cooling Plant", "price": 10.0},
]
const PAYOUT_PER_MINER_CYCLE_1_2: float = 2.0
const PAYOUT_PER_MINER_CYCLE_3_4: float = 1.0

var current_player_index: int
var player_positions: Array[int]
var tiles: Array[TileInfo]
var players: Array[PlayerData] = []
var current_cycle: int = 1
var turn_count: int = 1
var player_laps: Array[int] = []

signal player_changed(new_index: int)
signal player_position_changed(new_position: int, tile_slot: int)
signal player_data_changed(player_index: int, player_data: PlayerData)
signal turn_state_changed(player_index: int, turn_number: int, cycle_number: int)

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

	player_laps = []
	player_laps.resize(GameConfig.player_count)
	player_laps.fill(0)

	players = []
	players.resize(GameConfig.player_count)
	for index in range(GameConfig.player_count):
		var data: PlayerData = PlayerData.new()
		data.fiat_balance = GameConfig.starting_fiat_balance
		data.bitcoin_balance = GameConfig.starting_bitcoin_balance
		data.mining_power = GameConfig.starting_mining_power
		players[index] = data
		player_data_changed.emit(index, data)

	# Clear stale occupants from previous runs before seeding start tile.
	for tile_index in range(tiles.size()):
		tiles[tile_index].occupants = []
		tiles[tile_index].owner_index = -1
	# tile of position 0 starts with one player index per slot
	for index in range(GameConfig.player_count):
		tiles[0].occupants.append(index)
	current_cycle = 1
	turn_count = 1
	_emit_turn_state()

func advance_turn() -> void:
	current_player_index = (current_player_index + 1) % GameConfig.player_count
	turn_count += 1
	player_changed.emit(current_player_index)
	_emit_turn_state()

func move_player(player_index: int, steps: int, board_size: int) -> void:
	assert(player_index >= 0 and player_index < player_positions.size())
	assert(player_index >= 0 and player_index < player_laps.size())

	var current_tile: int = player_positions[player_index]
	var next_tile: int = (current_tile + steps) % board_size
	var cycle_changed: bool = false
	if current_tile + steps >= board_size:
		player_laps[player_index] += 1
		var next_cycle: int = player_laps[player_index] + 1
		if next_cycle > current_cycle:
			current_cycle = next_cycle
			cycle_changed = true

	var current_occupants: Array[int] = tiles[current_tile].occupants
	var next_occupants: Array[int] = tiles[next_tile].occupants
	current_occupants.erase(player_index)
	next_occupants.append(player_index)
	player_positions[player_index] = next_tile
	
	var next_slot: int = next_occupants.size() - 1
	player_position_changed.emit(next_tile, next_slot)
	if cycle_changed:
		_emit_turn_state()

func get_tile_info(tile_index: int) -> TileInfo:
	assert(not tiles.is_empty())
	assert(tile_index >= 0 and tile_index < tiles.size())
	return tiles[tile_index]

func get_player_fiat_balance(player_index: int) -> float:
	assert(player_index >= 0 and player_index < players.size())
	return players[player_index].fiat_balance

func get_player_bitcoin_balance(player_index: int) -> float:
	assert(player_index >= 0 and player_index < players.size())
	return players[player_index].bitcoin_balance

func get_energy_toll(tile: TileInfo) -> float:
	return get_tile_price(tile) * 0.1

func get_energy_toll_btc(tile: TileInfo) -> float:
	var exchange_rate: float = max(1.0, GameConfig.btc_exchange_rate_fiat)
	return get_energy_toll(tile) / exchange_rate

func get_payout_per_miner_for_cycle(cycle_number: int) -> float:
	if cycle_number <= 2:
		return PAYOUT_PER_MINER_CYCLE_1_2
	return PAYOUT_PER_MINER_CYCLE_3_4

func get_tile_price(tile: TileInfo) -> float:
	return _get_base_tile_price(tile) * _get_inflation_multiplier()

func get_tile_price_btc(tile: TileInfo) -> float:
	var exchange_rate: float = max(1.0, GameConfig.btc_exchange_rate_fiat)
	return get_tile_price(tile) / exchange_rate

func pay_energy_toll(
	payer_index: int,
	owner_index: int,
	amount: float,
	use_bitcoin: bool
) -> void:
	assert(payer_index >= 0 and payer_index < players.size())
	assert(owner_index >= 0 and owner_index < players.size())
	var payer: PlayerData = players[payer_index]
	var owner: PlayerData = players[owner_index]
	if use_bitcoin:
		payer.bitcoin_balance -= amount
		owner.bitcoin_balance += amount
	else:
		payer.fiat_balance -= amount
		owner.fiat_balance += amount
	player_data_changed.emit(payer_index, payer)
	player_data_changed.emit(owner_index, owner)

func _emit_turn_state() -> void:
	turn_state_changed.emit(current_player_index, turn_count, current_cycle)

func purchase_tile(player_index: int, tile_index: int, use_bitcoin: bool) -> bool:
	assert(player_index >= 0 and player_index < players.size())
	assert(tile_index >= 0 and tile_index < tiles.size())
	var tile: TileInfo = tiles[tile_index]
	if not _is_tile_buyable(tile):
		return false
	var price: float = get_tile_price(tile)
	if price <= 0.0:
		return false
	var player_data: PlayerData = players[player_index]
	if use_bitcoin:
		var price_btc: float = get_tile_price_btc(tile)
		player_data.bitcoin_balance -= price_btc
	else:
		if player_data.fiat_balance < price:
			return false
		player_data.fiat_balance -= price
	player_data_changed.emit(player_index, player_data)
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
			if GameConfig.disable_special_properties:
				info.tile_type = "property"
				info.city = _city_for_side(side_index)
				info.property_price = CITY_BASE_PRICE.get(info.city, 0.0)
			else:
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

func _get_base_tile_price(tile: TileInfo) -> float:
	if tile.tile_type == "property":
		return tile.property_price
	if tile.tile_type == "special_property":
		return tile.special_property_price
	return 0.0

func _get_inflation_multiplier() -> float:
	var inflation_cycles: int = int(floor(float(current_cycle) / 2.0))
	return pow(1.1, inflation_cycles)

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
