class_name GameState
extends RefCounted

const PlayerState = preload("res://scripts/state/player_state.gd")

var game_id: String
var turn_number: int
var current_player_index: int
var current_cycle: int
var players: Array[PlayerState]


func _init(config: Config) -> void:
    game_id = config.game_id
    turn_number = 1
    current_player_index = 0
    current_cycle = 1
    players = []
    players.resize(config.player_count)
    for index in range(config.player_count):
        var player: PlayerState = PlayerState.new(index)
        player.fiat_balance = 1000000.0
        players[index] = player
