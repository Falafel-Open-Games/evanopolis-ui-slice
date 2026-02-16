class_name PlayerData
extends RefCounted

var username: String
var fiat_balance: float
var bitcoin_balance: float
var mining_power: int
var accent_color: Color

func _init() -> void:
	username = ""
	fiat_balance = 0.0
	bitcoin_balance = 0.0
	mining_power = 0
	accent_color = Color(0, 0, 0, 1)
