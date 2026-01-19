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
const STRIP_TILE_ORDER := [
	"CornerTile",
	"Tile2",
	"Tile3",
	"Tile4",
	"Tile5",
	"Tile6",
]

func _ready() -> void:
	_apply_colors()
	print(get_board_tiles())

func _apply_colors() -> void:
	for side_index in range(SIDE_STRIP_NAMES.size()):
		var side_name: String = SIDE_STRIP_NAMES[side_index]
		var side := get_node_or_null("tiles/" + side_name)
		if side == null:
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

func get_board_tiles() -> Array[Node3D]:
	var tiles_list: Array[Node3D] = []
	var tiles_root := get_node_or_null("tiles")
	if tiles_root == null:
		return tiles_list

	# Start at SideStrip1 Tile4 and move counter-clockwise.
	var strip1 := tiles_root.get_node_or_null(SIDE_STRIP_NAMES[0])
	if strip1 == null:
		return tiles_list
	for tile_name in ["Tile4", "Tile5", "Tile6"]:
		var tile := strip1.get_node_or_null(tile_name)
		if tile is Node3D:
			tiles_list.append(tile)

	for index in range(1, SIDE_STRIP_NAMES.size()):
		var strip := tiles_root.get_node_or_null(SIDE_STRIP_NAMES[index])
		if strip == null:
			continue
		for tile_name in STRIP_TILE_ORDER:
			var tile := strip.get_node_or_null(tile_name)
			if tile is Node3D:
				tiles_list.append(tile)

	for tile_name in ["CornerTile", "Tile2", "Tile3"]:
		var tile := strip1.get_node_or_null(tile_name)
		if tile is Node3D:
			tiles_list.append(tile)

	return tiles_list
