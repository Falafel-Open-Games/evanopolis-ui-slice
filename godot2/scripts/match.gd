class_name GameMatch
extends RefCounted

const GameState = preload("res://scripts/state/game_state.gd")
const PlayerState = preload("res://scripts/state/player_state.gd")
const Client = preload("res://scripts/client.gd")
const Config = preload("res://scripts/config.gd")

var config: Config
var clients: Array[Client]
var rng: RandomNumberGenerator
var state: GameState
var has_started: bool = false
var player_ids: Array[String]
var next_event_seq: int = 1
var board_state: Dictionary = { }
var pending_action: Dictionary = { }


func _init(config_node: Config, client_nodes: Array[Client]) -> void:
    config = config_node
    assert(config)
    clients = []
    clients.resize(config.player_count)
    player_ids = []
    player_ids.resize(config.player_count)
    assert(client_nodes.size() <= clients.size())
    for index in range(client_nodes.size()):
        clients[index] = client_nodes[index]
    rng = RandomNumberGenerator.new()
    state = GameState.new(config)
    rng.seed = state.game_id.hash()
    board_state = _build_board_state(config.board_size)


func start_game() -> void:
    if has_started:
        return
    has_started = true
    _broadcast("rpc_game_started", [state.game_id])
    _broadcast("rpc_board_state", [board_state])
    _broadcast("rpc_turn_started", [state.current_player_index, state.turn_number, state.current_cycle])


func register_client_at_index(player_id: String, player_index: int, client: Client) -> String:
    if player_id.is_empty():
        return "invalid_player_id"
    if player_index < 0 or player_index >= clients.size():
        return "invalid_player_index"
    if clients[player_index] != null:
        return "player_slot_taken"
    if _player_index_from_id(player_id) >= 0:
        return "player_id_taken"
    clients[player_index] = client
    player_ids[player_index] = player_id
    _broadcast("rpc_player_joined", [player_id, player_index])
    if _has_all_clients():
        start_game()
    return ""


func assign_client(player_id: String, client: Client) -> Dictionary:
    if player_id.is_empty():
        return { "reason": "invalid_player_id", "player_index": -1 }
    var existing_index: int = _player_index_from_id(player_id)
    if existing_index >= 0:
        clients[existing_index] = client
        return { "reason": "", "player_index": existing_index, "reconnected": true }
    var empty_index: int = _first_empty_slot()
    if empty_index < 0:
        return { "reason": "match_full", "player_index": -1 }
    var reason: String = register_client_at_index(player_id, empty_index, client)
    return { "reason": reason, "player_index": empty_index, "reconnected": false }


func detach_client(player_id: String, player_index: int) -> void:
    assert(player_index >= 0 and player_index < clients.size())
    assert(player_ids[player_index] == player_id)
    clients[player_index] = null


func _has_all_clients() -> bool:
    for client in clients:
        if client == null:
            return false
    return true


func _player_index_from_id(player_id: String) -> int:
    for index in range(player_ids.size()):
        if player_ids[index] == player_id:
            return index
    return -1


func _first_empty_slot() -> int:
    for index in range(clients.size()):
        if clients[index] == null:
            return index
    return -1


func rpc_roll_dice(game_id: String, player_id: String) -> void:
    if not has_started:
        _send_to_player(_player_index_from_id(player_id), "rpc_action_rejected", ["match_not_started"])
        return
    if game_id != state.game_id:
        _send_to_player(_player_index_from_id(player_id), "rpc_action_rejected", ["invalid_game_id"])
        return
    var resolved_index: int = _player_index_from_id(player_id)
    if resolved_index < 0:
        return
    if resolved_index != state.current_player_index:
        _send_to_player(resolved_index, "rpc_action_rejected", ["not_current_player"])
        return
    if not pending_action.is_empty():
        _send_to_player(resolved_index, "rpc_action_rejected", ["pending_action_required"])
        return
    var die_1: int = rng.randi_range(1, 6)
    var die_2: int = rng.randi_range(1, 6)
    var total: int = die_1 + die_2
    _broadcast("rpc_dice_rolled", [die_1, die_2, total])
    _server_move_pawn(total)


func _server_move_pawn(steps: int) -> void:
    var board_size: int = config.board_size
    var player: PlayerState = state.players[state.current_player_index]
    var from_tile: int = player.position
    var to_tile: int = (from_tile + steps) % board_size
    var passed_tiles: Array[int] = _compute_passed_tiles_with_effects(from_tile, steps, board_size)
    player.position = to_tile
    _broadcast("rpc_pawn_moved", [from_tile, to_tile, passed_tiles])
    var landing_context: Dictionary = _build_landing_context(to_tile, state.current_player_index)
    _broadcast(
        "rpc_tile_landed",
        [
            to_tile,
            str(landing_context.get("tile_type", "")),
            str(landing_context.get("city", "")),
            int(landing_context.get("owner_index", -1)),
            float(landing_context.get("toll_due", 0.0)),
            str(landing_context.get("action_required", "")),
        ],
    )
    var action_required: String = str(landing_context.get("action_required", ""))
    if action_required == "buy_or_end_turn":
        _set_pending_action("buy_or_end_turn", to_tile)
        return
    if action_required == "pay_toll":
        _set_pending_action(
            "pay_toll",
            to_tile,
            {
                "owner_index": int(landing_context.get("owner_index", -1)),
                "amount": float(landing_context.get("toll_due", 0.0)),
            },
        )
        return
    if action_required == "end_turn":
        _set_pending_action("end_turn", to_tile)
        _advance_turn()
        return
    _set_pending_action(action_required, to_tile)


func rpc_end_turn(game_id: String, player_id: String) -> String:
    if not has_started:
        return "match_not_started"
    if game_id != state.game_id:
        return "invalid_game_id"
    var resolved_index: int = _player_index_from_id(player_id)
    if resolved_index < 0:
        return "invalid_player_id"
    if resolved_index != state.current_player_index:
        return "not_current_player"
    if pending_action.is_empty():
        return "no_pending_action"
    var pending_type: String = str(pending_action.get("type", ""))
    if pending_type != "buy_or_end_turn" and pending_type != "end_turn":
        return "action_not_allowed"
    _advance_turn()
    return ""


func rpc_buy_property(game_id: String, player_id: String, tile_index: int) -> String:
    if not has_started:
        return "match_not_started"
    if game_id != state.game_id:
        return "invalid_game_id"
    var resolved_index: int = _player_index_from_id(player_id)
    if resolved_index < 0:
        return "invalid_player_id"
    if resolved_index != state.current_player_index:
        return "not_current_player"
    if pending_action.is_empty():
        return "no_pending_action"
    if str(pending_action.get("type", "")) != "buy_or_end_turn":
        return "action_not_allowed"
    var pending_tile_index: int = int(pending_action.get("tile_index", -1))
    if pending_tile_index != tile_index:
        return "tile_mismatch"
    var tile: Dictionary = _tile_from_index(tile_index)
    if int(tile.get("owner_index", -1)) >= 0:
        return "property_already_owned"
    var tile_type: String = str(tile.get("tile_type", ""))
    if not _is_property_tile(tile_type):
        return "tile_not_buyable"
    var city: String = str(tile.get("city", ""))
    var price: float = _compute_property_price(city)
    var buyer: PlayerState = state.players[resolved_index]
    if buyer.fiat_balance < price:
        return "insufficient_fiat"
    buyer.fiat_balance -= price
    tile["owner_index"] = resolved_index
    var tiles: Array = board_state.get("tiles", [])
    tiles[tile_index] = tile
    board_state["tiles"] = tiles
    _broadcast("rpc_property_acquired", [resolved_index, tile_index, price])
    _advance_turn()
    return ""


func rpc_pay_toll(game_id: String, player_id: String) -> String:
    if not has_started:
        return "match_not_started"
    if game_id != state.game_id:
        return "invalid_game_id"
    var resolved_index: int = _player_index_from_id(player_id)
    if resolved_index < 0:
        return "invalid_player_id"
    if resolved_index != state.current_player_index:
        return "not_current_player"
    if pending_action.is_empty():
        return "no_pending_action"
    if str(pending_action.get("type", "")) != "pay_toll":
        return "action_not_allowed"
    var owner_index: int = int(pending_action.get("owner_index", -1))
    if owner_index < 0 or owner_index >= state.players.size():
        return "invalid_owner"
    if owner_index == resolved_index:
        return "invalid_owner"
    var amount: float = float(pending_action.get("amount", 0.0))
    if amount <= 0.0:
        return "invalid_toll_amount"
    var payer: PlayerState = state.players[resolved_index]
    if payer.fiat_balance < amount:
        return "insufficient_fiat"
    var owner: PlayerState = state.players[owner_index]
    payer.fiat_balance -= amount
    owner.fiat_balance += amount
    _broadcast("rpc_toll_paid", [resolved_index, owner_index, amount])
    _advance_turn()
    return ""


func _compute_passed_tiles_with_effects(from_tile: int, steps: int, board_size: int) -> Array[int]:
    var results: Array[int] = []
    if steps <= 0:
        return results
    var passes_start: bool = from_tile + steps >= board_size
    if passes_start:
        results.append(0)
        var player: PlayerState = state.players[state.current_player_index]
        player.laps += 1
        var next_cycle: int = player.laps + 1
        if next_cycle > state.current_cycle:
            state.current_cycle = next_cycle
            _broadcast("rpc_cycle_started", [state.current_cycle, _is_inflation_cycle(state.current_cycle)])
    return results


func _is_inflation_cycle(cycle: int) -> bool:
    return cycle % 2 == 0


func _build_landing_context(tile_index: int, landing_player_index: int) -> Dictionary:
    var tile: Dictionary = _tile_from_index(tile_index)
    assert(not tile.is_empty())
    var tile_type: String = str(tile.get("tile_type", ""))
    var city: String = str(tile.get("city", ""))
    var owner_index: int = int(tile.get("owner_index", -1))
    var miner_batches: int = int(tile.get("miner_batches", 0))
    var toll_due: float = 0.0
    if _is_property_tile(tile_type) and owner_index >= 0 and owner_index != landing_player_index:
        toll_due = _compute_toll(city, miner_batches)
    return {
        "tile_type": tile_type,
        "city": city,
        "owner_index": owner_index,
        "toll_due": toll_due,
        "action_required": _action_required_for_tile(tile_type, owner_index, landing_player_index),
    }


func _action_required_for_tile(tile_type: String, owner_index: int, landing_player_index: int) -> String:
    if tile_type == "incident":
        return "resolve_incident"
    if _is_property_tile(tile_type):
        if owner_index < 0:
            return "buy_or_end_turn"
        if owner_index != landing_player_index:
            return "pay_toll"
    return "end_turn"


func _is_property_tile(tile_type: String) -> bool:
    return tile_type == "property" or tile_type == "special_property"


func _tile_from_index(tile_index: int) -> Dictionary:
    var tiles: Array = board_state.get("tiles", [])
    assert(tile_index >= 0)
    assert(tile_index < tiles.size())
    return tiles[tile_index]


func _compute_toll(city: String, miner_batches: int) -> float:
    var property_price: float = _compute_property_price(city)
    return property_price * (0.10 + (0.025 * float(miner_batches)))


func _compute_property_price(city: String) -> float:
    var base_price: float = _base_property_price(city)
    var inflation_steps: int = int(state.current_cycle / 2)
    var multiplier: float = pow(1.1, inflation_steps)
    return base_price * multiplier


func _base_property_price(city: String) -> float:
    if city == "caracas":
        return 20000.0
    if city == "assuncion":
        return 50000.0
    if city == "ciudad_del_este":
        return 80000.0
    if city == "minsk":
        return 110000.0
    if city == "irkutsk":
        return 150000.0
    if city == "rockdale":
        return 200000.0
    assert(false)
    return 0.0


func _build_board_state(board_size: int) -> Dictionary:
    assert(board_size >= 24)
    assert((board_size - 6) % 6 == 0)
    var properties_per_city: int = int((board_size - 6) / 6)
    var tiles: Array[Dictionary] = []
    var index: int = 0
    tiles.append(
        {
            "index": index,
            "tile_type": "start",
            "city": "",
            "incident_kind": "",
            "owner_index": -1,
            "miner_batches": 0,
        },
    )
    index += 1
    index = _append_city_tiles(tiles, index, properties_per_city, "caracas")
    index = _append_incident_tile(tiles, index, "bear")
    index = _append_city_tiles(tiles, index, properties_per_city, "assuncion")
    index = _append_incident_tile(tiles, index, "bear")
    index = _append_city_tiles(tiles, index, properties_per_city, "ciudad_del_este")
    tiles.append(
        {
            "index": index,
            "tile_type": "inspection",
            "city": "",
            "incident_kind": "",
            "owner_index": -1,
            "miner_batches": 0,
        },
    )
    index += 1
    index = _append_city_tiles(tiles, index, properties_per_city, "minsk")
    index = _append_incident_tile(tiles, index, "bear")
    index = _append_city_tiles(tiles, index, properties_per_city, "irkutsk")
    index = _append_incident_tile(tiles, index, "bear")
    index = _append_city_tiles(tiles, index, properties_per_city, "rockdale")
    assert(index == board_size)
    assert(tiles.size() == board_size)
    return {
        "size": board_size,
        "tiles": tiles,
    }


func _append_city_tiles(tiles: Array[Dictionary], start_index: int, count: int, city_slug: String) -> int:
    var index: int = start_index
    for _i in range(count):
        tiles.append(
            {
                "index": index,
                "tile_type": "property",
                "city": city_slug,
                "incident_kind": "",
                "owner_index": -1,
                "miner_batches": 0,
            },
        )
        index += 1
    return index


func _append_incident_tile(tiles: Array[Dictionary], start_index: int, kind: String) -> int:
    tiles.append(
        {
            "index": start_index,
            "tile_type": "incident",
            "city": "",
            "incident_kind": kind,
            "owner_index": -1,
            "miner_batches": 0,
        },
    )
    return start_index + 1


func next_sequence() -> int:
    var seq: int = next_event_seq
    next_event_seq += 1
    return seq


func last_sequence() -> int:
    return next_event_seq - 1


func build_state_snapshot() -> Dictionary:
    var players_snapshot: Array[Dictionary] = []
    for player in state.players:
        players_snapshot.append(
            {
                "player_index": player.player_index,
                "fiat_balance": player.fiat_balance,
                "bitcoin_balance": player.bitcoin_balance,
                "position": player.position,
                "laps": player.laps,
                "in_inspection": player.in_inspection,
            },
        )
    return {
        "game_id": state.game_id,
        "turn_number": state.turn_number,
        "current_player_index": state.current_player_index,
        "current_cycle": state.current_cycle,
        "has_started": has_started,
        "board_state": board_state.duplicate(true),
        "players": players_snapshot,
        "pending_action": pending_action.duplicate(true),
    }


func _set_pending_action(action_type: String, tile_index: int, metadata: Dictionary = { }) -> void:
    pending_action = {
        "type": action_type,
        "player_index": state.current_player_index,
        "tile_index": tile_index,
        "game_id": state.game_id,
    }
    for key in metadata.keys():
        pending_action[key] = metadata[key]


func _clear_pending_action() -> void:
    pending_action = { }


func _advance_turn() -> void:
    _clear_pending_action()
    var next_player_index: int = state.current_player_index + 1
    if next_player_index >= clients.size():
        next_player_index = 0
        state.turn_number += 1
    state.current_player_index = next_player_index
    _broadcast("rpc_turn_started", [state.current_player_index, state.turn_number, state.current_cycle])


func _broadcast(method: String, args: Array) -> void:
    assert(method != "rpc_action_rejected")
    assert(method != "rpc_join_accepted")
    var seq: int = next_sequence()
    var log_args: Variant = args
    if method == "rpc_board_state" and args.size() > 0:
        var board_payload: Dictionary = args[0]
        var board_tiles: Array = board_payload.get("tiles", [])
        log_args = ["size=%d tiles=%d" % [int(board_payload.get("size", 0)), board_tiles.size()]]
    print("server: emit=%s seq=%d args=%s" % [method, seq, log_args])
    var payload: Array = [seq]
    payload.append_array(args)
    for client in clients:
        if client == null:
            continue
        client.callv(method, payload)


func _send_to_player(player_index: int, method: String, args: Array) -> void:
    if player_index < 0 or player_index >= clients.size():
        return
    var client: Client = clients[player_index]
    if client == null:
        return
    var payload: Array = [0]
    payload.append_array(args)
    client.callv(method, payload)
