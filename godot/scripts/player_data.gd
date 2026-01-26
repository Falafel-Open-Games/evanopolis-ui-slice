class_name PlayerData
extends RefCounted

var fiat_balance: float
var bitcoin_balance: float
var mining_power: int

func _init() -> void:
	fiat_balance = 0.0
	bitcoin_balance = 0.0
	mining_power = 0
