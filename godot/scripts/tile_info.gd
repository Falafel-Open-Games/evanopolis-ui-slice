class_name TileInfo
extends RefCounted

var tile_type: String
var city: String
var incident_kind: String
var occupants: Array[int]
var property_price: float
var special_property_name: String
var special_property_price: float
var owner_index: int
var miner_batches: int

func _init() -> void:
	tile_type = "unknown"
	city = ""
	incident_kind = ""
	occupants = []
	property_price = 0.0
	special_property_name = ""
	special_property_price = 0.0
	owner_index = -1
	miner_batches = 0
