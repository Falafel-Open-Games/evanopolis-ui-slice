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
const PAYOUT_PER_MINER: float = 2.0
const MAX_MINER_BATCHES_PER_PROPERTY: int = 4
const MINER_BATCH_PRICE_FIAT_BASE: float = 320000.0

var current_player_index: int
var player_positions: Array[int]
var tiles: Array[TileInfo]
var players: Array[PlayerData] = []
var current_cycle: int = 1
var turn_count: int = 1
var player_laps: Array[int] = []
var player_progress: Array[int] = []
var pending_miner_orders: Array[Dictionary] = []
var pending_miner_order_locked: Array[bool] = []

signal player_changed(new_index: int)
signal player_position_changed(new_position: int, tile_slot: int)
signal player_data_changed(player_index: int, player_data: PlayerData)
signal turn_state_changed(player_index: int, turn_number: int, cycle_number: int)
signal miner_order_locked(player_index: int, locked: bool)
signal miner_order_committed(player_index: int)
signal miner_batches_changed(tile_index: int, miner_batches: int, owner_index: int)

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

	player_progress = []
	player_progress.resize(GameConfig.player_count)
	player_progress.fill(0)

	pending_miner_orders = []
	pending_miner_orders.resize(GameConfig.player_count)
	pending_miner_order_locked = []
	pending_miner_order_locked.resize(GameConfig.player_count)

	players = []
	players.resize(GameConfig.player_count)
	for index in range(GameConfig.player_count):
		var data: PlayerData = PlayerData.new()
		data.fiat_balance = GameConfig.starting_fiat_balance
		data.bitcoin_balance = GameConfig.starting_bitcoin_balance
		data.mining_power = GameConfig.starting_mining_power
		players[index] = data
		player_data_changed.emit(index, data)
		pending_miner_orders[index] = {}
		pending_miner_order_locked[index] = false

	# Clear stale occupants from previous runs before seeding start tile.
	for tile_index in range(tiles.size()):
		tiles[tile_index].occupants = []
		tiles[tile_index].owner_index = -1
		tiles[tile_index].miner_batches = 0
		miner_batches_changed.emit(tile_index, 0, -1)
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
	assert(player_index >= 0 and player_index < player_progress.size())

	var current_tile: int = player_positions[player_index]
	var next_tile: int = (current_tile + steps) % board_size
	var cycle_changed: bool = false
	player_progress[player_index] += steps
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
	var price: float = get_tile_price(tile)
	return (price * 0.1) + (price * 0.025 * float(tile.miner_batches))

func get_energy_toll_btc(tile: TileInfo) -> float:
	var exchange_rate: float = max(1.0, GameConfig.btc_exchange_rate_fiat)
	var base_price: float = _get_base_tile_price(tile)
	var base_toll: float = (base_price * 0.1) + (base_price * 0.025 * float(tile.miner_batches))
	return (base_toll * 0.9) / exchange_rate

func get_payout_per_miner_for_cycle(_cycle_number: int) -> float:
	return PAYOUT_PER_MINER

func apply_property_payout(tile_index: int) -> void:
	assert(tile_index >= 0 and tile_index < tiles.size())
	var tile: TileInfo = tiles[tile_index]
	if tile.tile_type != "property":
		return
	if tile.owner_index < 0:
		return
	if tile.miner_batches <= 0:
		return
	var payout_per_miner: float = PAYOUT_PER_MINER
	var total_payout: float = payout_per_miner * float(tile.miner_batches)
	if total_payout <= 0.0:
		return
	var owner_data: PlayerData = players[tile.owner_index]
	owner_data.bitcoin_balance += total_payout
	player_data_changed.emit(tile.owner_index, owner_data)

func get_tile_price(tile: TileInfo) -> float:
	return _get_base_tile_price(tile) * _get_inflation_multiplier()

func get_tile_price_btc(tile: TileInfo) -> float:
	var exchange_rate: float = max(1.0, GameConfig.btc_exchange_rate_fiat)
	return (_get_base_tile_price(tile) * 0.9) / exchange_rate

func get_miner_batch_price_fiat() -> float:
	return MINER_BATCH_PRICE_FIAT_BASE * _get_inflation_multiplier()

func get_miner_batch_price_btc() -> float:
	var exchange_rate: float = max(1.0, GameConfig.btc_exchange_rate_fiat)
	return (MINER_BATCH_PRICE_FIAT_BASE * 0.9) / exchange_rate

func get_owned_property_indices(player_index: int) -> Array[int]:
	assert(player_index >= 0 and player_index < GameConfig.player_count)
	var results: Array[int] = []
	for tile_index in range(tiles.size()):
		var tile: TileInfo = tiles[tile_index]
		if tile.tile_type == "property" and tile.owner_index == player_index:
			results.append(tile_index)
	return results

func get_pending_miner_order(player_index: int) -> Dictionary:
	assert(player_index >= 0 and player_index < GameConfig.player_count)
	return pending_miner_orders[player_index]

func can_place_miner_order(player_index: int) -> bool:
	assert(player_index >= 0 and player_index < GameConfig.player_count)
	return not pending_miner_order_locked[player_index]

func set_pending_miner_order(player_index: int, order: Dictionary, use_bitcoin: bool) -> bool:
	assert(player_index >= 0 and player_index < players.size())
	assert(can_place_miner_order(player_index))
	var total_batches: int = 0
	for tile_key in order.keys():
		var tile_index: int = int(tile_key)
		assert(tile_index >= 0 and tile_index < tiles.size())
		var tile: TileInfo = tiles[tile_index]
		assert(tile.tile_type == "property")
		assert(tile.owner_index == player_index)
		var batches: int = int(order[tile_key])
		if batches <= 0:
			continue
		assert(batches <= MAX_MINER_BATCHES_PER_PROPERTY - tile.miner_batches)
		total_batches += batches
	if total_batches == 0:
		return false
	var player_data: PlayerData = players[player_index]
	if use_bitcoin:
		var total_btc: float = float(total_batches) * get_miner_batch_price_btc()
		if player_data.bitcoin_balance < total_btc:
			return false
		player_data.bitcoin_balance -= total_btc
	else:
		var total_fiat: float = float(total_batches) * get_miner_batch_price_fiat()
		if player_data.fiat_balance < total_fiat:
			return false
		player_data.fiat_balance -= total_fiat
	pending_miner_orders[player_index] = order.duplicate(true)
	pending_miner_order_locked[player_index] = true
	player_data_changed.emit(player_index, player_data)
	miner_order_locked.emit(player_index, true)
	return true

func apply_pending_miner_orders(player_index: int) -> void:
	assert(player_index >= 0 and player_index < players.size())
	if not pending_miner_order_locked[player_index]:
		return
	var order: Dictionary = pending_miner_orders[player_index]
	for tile_key in order.keys():
		var tile_index: int = int(tile_key)
		assert(tile_index >= 0 and tile_index < tiles.size())
		var tile: TileInfo = tiles[tile_index]
		var batches: int = int(order[tile_key])
		if batches > 0:
			tile.miner_batches += batches
			miner_batches_changed.emit(tile_index, tile.miner_batches, tile.owner_index)
	pending_miner_orders[player_index] = {}
	pending_miner_order_locked[player_index] = false
	miner_order_locked.emit(player_index, false)
	miner_order_committed.emit(player_index)

func apply_all_pending_miner_orders() -> void:
	for player_index in range(pending_miner_orders.size()):
		apply_pending_miner_orders(player_index)

func pay_energy_toll(
	payer_index: int,
	owner_index: int,
	amount: float,
	use_bitcoin: bool
) -> bool:
	assert(payer_index >= 0 and payer_index < players.size())
	assert(owner_index >= 0 and owner_index < players.size())
	assert(amount >= 0.0)
	var payer: PlayerData = players[payer_index]
	var owner_data: PlayerData = players[owner_index]
	if use_bitcoin:
		if payer.bitcoin_balance < amount:
			return false
		payer.bitcoin_balance -= amount
		owner_data.bitcoin_balance += amount
	else:
		if payer.fiat_balance < amount:
			return false
		payer.fiat_balance -= amount
		owner_data.fiat_balance += amount
	player_data_changed.emit(payer_index, payer)
	player_data_changed.emit(owner_index, owner_data)
	return true

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
		if player_data.bitcoin_balance < price_btc:
			return false
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
