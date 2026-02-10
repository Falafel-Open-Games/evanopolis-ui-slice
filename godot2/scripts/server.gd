class_name HeadlessServer
extends RefCounted

const GameMatch = preload("res://scripts/match.gd")
const NetworkClient = preload("res://scripts/network_client.gd")
const Config = preload("res://scripts/config.gd")

var matches: Dictionary
var peer_slots: Dictionary


func _init() -> void:
    matches = { }
    peer_slots = { }


func create_match(config: Config) -> GameMatch:
    var game_match: GameMatch = GameMatch.new(config, [])
    matches[config.game_id] = game_match
    return game_match


func register_remote_client(game_id: String, player_id: String, peer_id: int, server_node: Node) -> Dictionary:
    var game_match: GameMatch = matches.get(game_id, null)
    if game_match == null:
        return { "reason": "invalid_game_id", "player_index": -1, "seq": 0 }
    if peer_slots.has(peer_id):
        return { "reason": "peer_already_registered", "player_index": -1, "seq": 0 }
    var client: NetworkClient = NetworkClient.new(server_node, peer_id)
    var result: Dictionary = game_match.assign_client(player_id, client)
    var reason: String = str(result.get("reason", ""))
    if not reason.is_empty():
        result["seq"] = 0
        return result
    result["last_seq"] = game_match.last_sequence()
    peer_slots[peer_id] = {
        "game_id": game_id,
        "player_id": player_id,
        "player_index": int(result.get("player_index", -1)),
    }
    result["seq"] = 0
    return result


func rpc_roll_dice(game_id: String, player_id: String, sender_peer_id: int = -1) -> Dictionary:
    var game_match: GameMatch = matches.get(game_id, null)
    if game_match == null:
        return { "reason": "invalid_game_id", "seq": 0 }
    if sender_peer_id >= 0:
        var slot: Dictionary = peer_slots.get(sender_peer_id, { })
        if slot.is_empty():
            return { "reason": "unregistered_peer", "seq": 0 }
        if slot.get("game_id", "") != game_id:
            return { "reason": "peer_game_id_mismatch", "seq": 0 }
        if str(slot.get("player_id", "")) != player_id:
            return { "reason": "peer_player_mismatch", "seq": 0 }
    game_match.rpc_roll_dice(game_id, player_id)
    return { "reason": "", "seq": 0 }
