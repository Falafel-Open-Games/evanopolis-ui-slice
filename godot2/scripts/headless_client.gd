class_name HeadlessClient
extends "res://scripts/client.gd"

const HeadlessServer = preload("res://scripts/server.gd")

var server: HeadlessServer
var game_id: String = ""
var current_player_index: int = 0
var player_index: int = 0
var player_id: String = ""


func _init(server_node: HeadlessServer, player_slot: int, player_id_value: String) -> void:
    server = server_node
    assert(server)
    player_index = player_slot
    player_id = player_id_value


func start_turn_prompt() -> void:
    _log_prompt("press enter to roll dice")
    await _wait_for_enter()
    _request_roll()


func _request_roll() -> void:
    _log_client("roll dice: game_id=%s, player_id=%s" % [game_id, player_id])
    server.rpc_roll_dice(game_id, player_id, -1)


func rpc_game_started(seq: int, new_game_id: String) -> void:
    game_id = new_game_id
    _log_server("game started: game_id=%s" % game_id)


func rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void:
    current_player_index = player_index
    _log_server("turn started: player=%d, turn=%d, cycle=%d" % [player_index, turn_number, cycle])
    if player_index != self.player_index:
        return
    await start_turn_prompt()


func rpc_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
    _log_server("dice rolled: die1=%d, die2=%d, total=%d" % [die_1, die_2, total])


func rpc_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    _log_server("pawn moved: from=%d, to=%d, passed_tiles=%s" % [from_tile, to_tile, passed_tiles])


func rpc_tile_landed(seq: int, tile_index: int) -> void:
    _log_server("tile landed: index=%d" % tile_index)


func rpc_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
    _log_server("cycle started: cycle=%d, inflation_active=%s" % [cycle, inflation_active])


func rpc_action_rejected(seq: int, reason: String) -> void:
    _log_server("action rejected: reason=%s" % reason)


func _wait_for_enter() -> void:
    if OS.has_method("read_string_from_stdin"):
        OS.read_string_from_stdin()
        return
    _log_note("stdin not available; continuing")


func _log_server(message: String) -> void:
    print("server[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_client(message: String) -> void:
    print("client[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_prompt(message: String) -> void:
    print("prompt[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])


func _log_note(message: String) -> void:
    print("note[p=%d id=%s g=%s]: %s" % [player_index, player_id, game_id, message])
