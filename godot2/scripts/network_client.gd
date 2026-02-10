class_name NetworkClient
extends "res://scripts/client.gd"

var server_node: Node
var peer_id: int = 0


func _init(server_host: Node, peer: int) -> void:
    server_node = server_host
    peer_id = peer
    assert(server_node)
    assert(peer_id > 0)


func rpc_game_started(seq: int, new_game_id: String) -> void:
    server_node.rpc_id(peer_id, "rpc_game_started", seq, new_game_id)


func rpc_turn_started(seq: int, player_index: int, turn_number: int, cycle: int) -> void:
    server_node.rpc_id(peer_id, "rpc_turn_started", seq, player_index, turn_number, cycle)


func rpc_player_joined(seq: int, player_id: String, player_index: int) -> void:
    server_node.rpc_id(peer_id, "rpc_player_joined", seq, player_id, player_index)


func rpc_dice_rolled(seq: int, die_1: int, die_2: int, total: int) -> void:
    server_node.rpc_id(peer_id, "rpc_dice_rolled", seq, die_1, die_2, total)


func rpc_pawn_moved(seq: int, from_tile: int, to_tile: int, passed_tiles: Array[int]) -> void:
    server_node.rpc_id(peer_id, "rpc_pawn_moved", seq, from_tile, to_tile, passed_tiles)


func rpc_tile_landed(seq: int, tile_index: int) -> void:
    server_node.rpc_id(peer_id, "rpc_tile_landed", seq, tile_index)


func rpc_cycle_started(seq: int, cycle: int, inflation_active: bool) -> void:
    server_node.rpc_id(peer_id, "rpc_cycle_started", seq, cycle, inflation_active)


func rpc_action_rejected(seq: int, reason: String) -> void:
    server_node.rpc_id(peer_id, "rpc_action_rejected", seq, reason)
