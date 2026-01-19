@tool
extends Node3D

const CITY_COLORS := {
	"Caracas": Color("#2b2b2b"),
	"Assuncion": Color("#404040"),
	"Ciudad del Este": Color("#595959"),
	"Minsk": Color("#737373"),
	"Irkutsk": Color("#8f8f8f"),
	"Rockdale": Color("#adadad"),
}

const CITY_ORDER := [
	"Rockdale",
	"Caracas",
	"Assuncion",
	"Ciudad del Este",
	"Minsk",
	"Irkutsk",
]

const SIDE_STRIP_NAMES := [
	"SideStrip1",
	"SideStrip2",
	"SideStrip3",
	"SideStrip4",
	"SideStrip5",
	"SideStrip6",
]

const CENTER_TILE_NAME := "Tile4"

func _ready() -> void:
	_apply_colors()

func _apply_colors() -> void:
	for side_index in range(SIDE_STRIP_NAMES.size()):
		var side_name: String = SIDE_STRIP_NAMES[side_index]
		var side := get_node_or_null("tiles/" + side_name)
		if side == null:
			print("null side")
			continue

		var prev_city: String = CITY_ORDER[side_index]
		var next_city: String = CITY_ORDER[(side_index + 1) % CITY_ORDER.size()]

		_set_tile_color(side, "CornerTile", CITY_COLORS[prev_city])
		_set_tile_color(side, "Tile2", CITY_COLORS[prev_city])
		_set_tile_color(side, "Tile3", CITY_COLORS[prev_city])

		_set_tile_color(side, CENTER_TILE_NAME, Color.WHITE)

		_set_tile_color(side, "Tile5", CITY_COLORS[next_city])
		_set_tile_color(side, "Tile6", CITY_COLORS[next_city])

func _set_tile_color(parent: Node, tile_name: String, color: Color) -> void:
	var tile := parent.get_node_or_null(tile_name)
	if tile is BoardTile:
		tile.tile_color = color
