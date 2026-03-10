class_name GameState
extends Node

const SIDE_COUNT: int = 6
const CITY_BASE_PRICE: Dictionary = {
    "Caracas": 3.0,
    "Assuncion": 4.0,
    "Ciudad del Este": 5.0,
    "Minsk": 6.0,
    "Irkutsk": 7.0,
    "Rockdale": 8.0,
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
const MINER_BATCH_PRICE_FIAT_BASE: float = 12
const MORTGAGE_RECEIVE_RATE: float = 0.8
const MORTGAGE_PAY_RATE: float = 1.2
const EXIT_PRISION_COST: float = 2

var current_player_index: int
var player_positions: Array[int]
var tiles: Array[TileInfo]
var players: Array[PlayerData] = []
var current_cycle: int = 1
var turn_count: int = 1
var inspection_tile_index = -1
var player_laps: Array[int] = []
var player_progress: Array[int] = []
var player_event_cards: Array[Dictionary] = []
var pending_miner_orders: Array[Dictionary] = []
var pending_miner_order_locked: Array[bool] = []

signal player_changed(new_index: int)
signal player_position_changed(new_position: int, tile_slot: int)
signal player_data_changed(player_index: int, player_data: PlayerData)
signal player_money_fiat_spent(player_index: int, spent_value: float)
signal player_money_bitcoin_spent(player_index: int, spent_value: float)
signal player_money_fiat_received(player_index: int, spent_value: float)
signal player_money_bitcoin_received(player_index: int, spent_value: float)
signal player_arrested_changed(player_index: int, arrested_status: bool)
signal turn_state_changed(player_index: int, turn_number: int, cycle_number: int)
signal miner_order_locked(player_index: int, locked: bool)
signal miner_order_committed(player_index: int)
signal miner_batches_changed(tile_index: int, miner_batches: int, owner_index: int)
signal property_owner_changed(tile_index: int, owner_index: int)
signal property_mortgaged_changed(tile_index: int, is_mortgaged: bool, operation_value: float)
signal state_reset()
signal match_winner_player_data(player_data: PlayerData)

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

    player_event_cards = []
    player_event_cards.resize(GameConfig.player_count)

    pending_miner_orders = []
    pending_miner_orders.resize(GameConfig.player_count)
    pending_miner_order_locked = []
    pending_miner_order_locked.resize(GameConfig.player_count)

    players = []
    players.resize(GameConfig.player_count)
    for index in range(GameConfig.player_count):
        var data: PlayerData = PlayerData.new()
        data.username = "Player %s" % str(index + 1)
        data.fiat_balance = GameConfig.starting_fiat_balance
        data.bitcoin_balance = GameConfig.starting_bitcoin_balance
        data.mining_power = GameConfig.starting_mining_power
        players[index] = data
        player_data_changed.emit(index, data)
        player_event_cards[index] = {}
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
    state_reset.emit()

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

func teleport_player_to_tile(player_index: int, tile_index: int) -> void:
    var current_tile: int = player_positions[player_index]
    var current_occupants: Array[int] = tiles[current_tile].occupants
    var next_occupants: Array[int] = tiles[tile_index].occupants
    current_occupants.erase(player_index)
    next_occupants.append(player_index)
    player_positions[player_index] = tile_index
    var next_slot: int = next_occupants.size() - 1
    player_position_changed.emit(tile_index, next_slot)

func get_tile_info(tile_index: int) -> TileInfo:
    assert(not tiles.is_empty())
    assert(tile_index >= 0 and tile_index < tiles.size())
    return tiles[tile_index]

func get_player_username(player_index: int) -> String:
    assert(player_index >= 0 and player_index < players.size())
    return players[player_index].username

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

func check_winner_by_btc() -> bool:
    # It's impossible to win during first cycle
    if current_cycle < 2:
        return false

    for player in players:
        # print("%s: %s BTC" % [players[i].username, players[i].bitcoin_balance])
        if player.bitcoin_balance >= GameConfig.btc_winning_value:
            match_winner_player_data.emit(player)
            return true

    return false

func check_winner_by_time() -> void:
    var best_player: PlayerData
    var has_best := false

    for player in players:
        if not has_best:
            best_player = player
            has_best = true
            continue

        # Compare BTC first
        if player.bitcoin_balance > best_player.bitcoin_balance:
            best_player = player
        elif player.bitcoin_balance == best_player.bitcoin_balance:
            # Tie on BTC: compare EVA
            if player.fiat_balance > best_player.fiat_balance:
                best_player = player

    print("best_player: %s" % best_player.username)
    match_winner_player_data.emit(best_player)


func apply_property_payout(tile_index: int) -> void:
    assert(tile_index >= 0 and tile_index < tiles.size())
    var tile: TileInfo = tiles[tile_index]
    if tile.tile_type != Utils.TileType.PROPERTY:
        return
    if tile.owner_index < 0:
        return
    if tile.miner_batches <= 0:
        return
    if tile.is_mortgaged:
        return
    var payout_per_miner: float = PAYOUT_PER_MINER
    var total_payout: float = payout_per_miner * float(tile.miner_batches)
    if total_payout <= 0.0:
        return
    var owner_data: PlayerData = players[tile.owner_index]
    if owner_data.is_arrested:
        return
    owner_data.bitcoin_balance += total_payout
    player_data_changed.emit(tile.owner_index, owner_data)

func get_player_accent_color(player_index: int) -> Color:
    assert(player_index >= 0 and player_index < players.size())
    return players[player_index].accent_color

func set_accent_color(player_index: int, new_color: Color) -> void:
    if player_index < 0 or player_index >= players.size():
        return

    players[player_index].accent_color = new_color

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
        if tile.tile_type == Utils.TileType.PROPERTY and tile.owner_index == player_index:
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
        assert(tile.tile_type == Utils.TileType.PROPERTY)
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
    print("pay_energy_toll")
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
        if not spend_money_fiat(payer_index, amount):
            return false
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
    property_owner_changed.emit(tile_index, player_index)
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
                    info.tile_type = Utils.TileType.START
                3:
                    info.tile_type = Utils.TileType.INSPECTION
                    inspection_tile_index = tile_index
                1, 2, 4, 5:
                    info.tile_type = Utils.TileType.INCIDENT
                    info.incident_kind = _incident_kind_for_side(side_index)
        elif side_slot == 1:
            if GameConfig.disable_special_properties:
                info.tile_type = Utils.TileType.PROPERTY
                info.city = _city_for_side(side_index)
                info.property_price = CITY_BASE_PRICE.get(info.city, 0.0)
            else:
                info.tile_type = Utils.TileType.SPECIAL_PROPERTY
                var special_index: int = side_index
                if special_index >= 0 and special_index < SPECIAL_PROPERTIES.size():
                    info.special_property_name = SPECIAL_PROPERTIES[special_index]["name"]
                    info.special_property_price = SPECIAL_PROPERTIES[special_index]["price"]
        else:
            info.tile_type = Utils.TileType.PROPERTY
            info.city = _city_for_side(side_index)
            info.property_price = CITY_BASE_PRICE.get(info.city, 0.0)

        tiles[tile_index] = info

func _get_base_tile_price(tile: TileInfo) -> float:
    if tile.tile_type == Utils.TileType.PROPERTY:
        return tile.property_price
    if tile.tile_type == Utils.TileType.SPECIAL_PROPERTY:
        return tile.special_property_price
    return 0.0

func _get_inflation_multiplier() -> float:
    return 1.0

    # TODO: implement inflation project wide
    # var inflation_cycles: int = int(floor(float(current_cycle) / 2.0))
    # return pow(1.1, inflation_cycles)

func _is_tile_buyable(tile: TileInfo) -> bool:
    return (
        (tile.tile_type == Utils.TileType.PROPERTY or tile.tile_type == Utils.TileType.SPECIAL_PROPERTY)
        and tile.owner_index == -1
    )

func _get_tiles_per_side() -> int:
    assert(GameConfig.board_size % SIDE_COUNT == 0)
    @warning_ignore("integer_division")
    return GameConfig.board_size / SIDE_COUNT

func _incident_kind_for_side(side_index: int) -> int:
    match side_index:
        1, 4:
            return Utils.CardEffectDeckType.BEAR
        2, 5:
            return Utils.CardEffectDeckType.BULL
    return -1

func _city_for_side(side_index: int) -> String:
    assert(side_index >= 0 and side_index < Palette.CITY_ORDER.size())
    return Palette.CITY_ORDER[side_index]

func flip_incident_tile(tile_index: int) -> void:
    assert(tile_index >= 0 and tile_index < tiles.size())
    match tiles[tile_index].incident_kind:
        Utils.CardEffectDeckType.BEAR:
            tiles[tile_index].incident_kind = Utils.CardEffectDeckType.BULL
            print("flip_incident_tile from BEAR to BULL")
        Utils.CardEffectDeckType.BULL:
            tiles[tile_index].incident_kind = Utils.CardEffectDeckType.BEAR
            print("flip_incident_tile from BULL to BEAR")

func can_player_mortgage(player_index: int, tile: TileInfo) -> bool:
    return(
        (tile.tile_type == Utils.TileType.PROPERTY or tile.tile_type == Utils.TileType.SPECIAL_PROPERTY)
        and tile.owner_index == player_index and not tile.is_mortgaged
    )

func can_player_unmortgage(player_index: int, tile: TileInfo) -> bool:
    var unmortgage_price = tile.property_price * MORTGAGE_PAY_RATE
    var payer: PlayerData = players[player_index]
    var has_payer_funds = payer.fiat_balance >= unmortgage_price

    return(
        (tile.tile_type == Utils.TileType.PROPERTY or tile.tile_type == Utils.TileType.SPECIAL_PROPERTY)
        and tile.owner_index == player_index and tile.is_mortgaged and has_payer_funds
    )

func mortgage_property(player_index: int, tile_index: int) -> void:
    var info: TileInfo = get_tile_info(tile_index)

    if not can_player_mortgage(player_index, info):
        return

    tiles[tile_index].is_mortgaged = true
    var mortgage_value = tiles[tile_index].property_price * MORTGAGE_RECEIVE_RATE
    var payer: PlayerData = players[player_index]
    payer.fiat_balance += mortgage_value
    player_data_changed.emit(player_index, payer)
    property_mortgaged_changed.emit(tile_index, true, mortgage_value)

func unmortgage_property(player_index: int, tile_index: int) -> void:
    var info: TileInfo = get_tile_info(tile_index)
    var unmortgage_price = tiles[tile_index].property_price * MORTGAGE_PAY_RATE

    if not can_player_unmortgage(player_index, info):
        return

    tiles[tile_index].is_mortgaged = false
    if spend_money_fiat(player_index, unmortgage_price):
        property_mortgaged_changed.emit(tile_index, false, unmortgage_price)

func is_player_arrested(player_index: int) -> bool:
    var player: PlayerData = players[player_index]
    return player.is_arrested

func can_player_pay_exit_prision(player_index: int) -> bool:
    var player: PlayerData = players[player_index]
    return player.fiat_balance >= EXIT_PRISION_COST and player.is_arrested

func arrest_player(player_index: int) -> void:
    if is_player_arrested(player_index):
        return

    var player: PlayerData = players[player_index]
    player.is_arrested = true
    player_data_changed.emit(player_index, player)
    player_arrested_changed.emit(player_index, true)

func pay_and_release_player(player_index: int) -> void:
    if not is_player_arrested(player_index):
        return

    if spend_money_fiat(player_index, EXIT_PRISION_COST):
        release_arrested_player(player_index)

func release_arrested_player(player_index: int) -> void:
    if not is_player_arrested(player_index):
        return

    var player: PlayerData = players[player_index]
    player.is_arrested = false
    player_data_changed.emit(player_index, player)
    player_arrested_changed.emit(player_index, false)

func spend_money_fiat(player_index: int, spent_value: float) -> bool:
    print("spend_money_fiat %s %s" % [player_index, spent_value])
    var player: PlayerData = players[player_index]
    if player.fiat_balance < spent_value:
        return false

    player.fiat_balance -= spent_value
    player_money_fiat_spent.emit(player_index, spent_value)
    player_data_changed.emit(player_index, player)
    return true

func spend_money_btc(player_index: int, spent_value: float) -> bool:
    print("spend_money_btc %s %s" % [player_index, spent_value])
    var player: PlayerData = players[player_index]
    if player.bitcoin_balance < spent_value:
        return false

    player.bitcoin_balance -= spent_value
    player_money_bitcoin_spent.emit(player_index, spent_value)
    player_data_changed.emit(player_index, player)
    return true

func receive_money_fiat(player_index: int, received_value: float) -> void:
    print("receive_money_fiat %s %s" % [player_index, received_value])
    var player: PlayerData = players[player_index]
    player.fiat_balance += received_value
    player_money_fiat_received.emit(player_index, received_value)
    player_data_changed.emit(player_index, player)

func receive_money_bitcoin(player_index: int, received_value: float) -> void:
    print("receive_money_fiat %s %s" % [player_index, received_value])
    var player: PlayerData = players[player_index]
    player.bitcoin_balance += received_value
    player_money_bitcoin_received.emit(player_index, received_value)
    player_data_changed.emit(player_index, player)

func get_event_card_amount(player_index: int, event_card_type: Utils.CardEffectType) -> int:
    var card_id = Utils.CardEffectType.keys()[event_card_type]
    var cards := player_event_cards[player_index]
    return cards.get(card_id, 0)

func consume_event_card(player_index: int, event_card_type: Utils.CardEffectType, amount: int = 1) -> bool:
    if get_event_card_amount(player_index, event_card_type) < amount:
        return false

    receive_event_card(player_index, event_card_type, -amount)
    return true

func receive_event_card(player_index: int, event_card_type: Utils.CardEffectType, amount: int) -> void:
    var card_id = Utils.CardEffectType.keys()[event_card_type]
    var cards := player_event_cards[player_index]
    var current: int = cards.get(card_id, 0)
    current += amount
    if current <= 0:
        cards.erase(card_id)
    else:
        cards[card_id] = current
