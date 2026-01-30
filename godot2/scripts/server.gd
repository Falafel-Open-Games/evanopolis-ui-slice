class_name HeadlessServer
extends RefCounted

const GameMatch = preload("res://scripts/match.gd")
const Client = preload("res://scripts/client.gd")

var matches: Dictionary


func _init() -> void:
    matches = {}


func create_match(config: Config, clients: Array[Client]) -> GameMatch:
    var match: GameMatch = GameMatch.new(config, clients)
    matches[config.game_id] = match
    return match


func rpc_roll_dice(game_id: String, player_index: int) -> void:
    var match: GameMatch = matches.get(game_id, null)
    if match == null:
        return
    match.rpc_roll_dice(game_id, player_index)
