extends Node

@export_enum("24:24", "30:30", "36:36") var board_size: int = 24
@export_range(2, 6, 1) var player_count: int = 6
@export_enum("10:10", "30:30", "60:60") var turn_duration: int = 30
@export var starting_fiat_balance: float = 1000000.0
@export var starting_bitcoin_balance: float = 1.0
@export var starting_mining_power: int = 0
@export var disable_special_properties: bool = true
@export var btc_exchange_rate_fiat: float = 100000.0
@export var game_id: String = ""
@export var build_id: String = "wlutkokvzusx"
