@tool
extends Node

const SIDE_STRIP_NAMES: Array[String] = [
	"SideStrip1",
	"SideStrip2",
	"SideStrip3",
	"SideStrip4",
	"SideStrip5",
	"SideStrip6",
]

const CENTER_TILE_NAME: String = "Tile4"
const STRIP_TILE_ORDER: Array[String] = [
	"CornerTile",
	"Tile2",
	"Tile3",
	"Tile4",
	"Tile5",
	"Tile6",
]

func _ready() -> void:
	_apply_colors()

func _apply_colors() -> void:
	var city_order: Array[String] = Palette.CITY_ORDER
	var last_city: String = city_order[city_order.size() - 1]

	for side_index in range(SIDE_STRIP_NAMES.size()):
		var side_name: String = SIDE_STRIP_NAMES[side_index]
		var side: Node = get_node_or_null("../tiles/" + side_name)
		if side == null:
			continue

		var prev_city: String
		var next_city: String
		if side_index == 0:
			prev_city = last_city
			next_city = city_order[0]
		else:
			prev_city = city_order[side_index - 1]
			next_city = city_order[side_index]

		var prev_color: Color = Palette.CITY_COLORS_BY_NAME.get(prev_city, Color.WHITE)
		var next_color: Color = Palette.CITY_COLORS_BY_NAME.get(next_city, Color.WHITE)

		_set_tile_color(side, "CornerTile", prev_color)
		_set_tile_color(side, "Tile2", prev_color)
		_set_tile_color(side, "Tile3", prev_color)

		_set_tile_color(side, CENTER_TILE_NAME, Color.WHITE)

		_set_tile_color(side, "Tile5", next_color)
		_set_tile_color(side, "Tile6", next_color)

func _set_tile_color(parent: Node, tile_name: String, color: Color) -> void:
	var tile: Node = parent.get_node_or_null(tile_name)
	if tile is BoardTile:
		tile.tile_color = color

func get_board_tiles() -> Array[Node3D]:
	var tiles_list: Array[Node3D] = []
	var tiles_root: Node = get_node_or_null("../tiles")
	if tiles_root == null:
		return tiles_list

	# Start at SideStrip1 Tile4 and move counter-clockwise.
	var strip1: Node = tiles_root.get_node_or_null(SIDE_STRIP_NAMES[0])
	if strip1 == null:
		return tiles_list
	for tile_name in ["Tile4", "Tile5", "Tile6"]:
		var tile: Node = strip1.get_node_or_null(tile_name)
		if tile is Node3D:
			tiles_list.append(tile)

	for index in range(1, SIDE_STRIP_NAMES.size()):
		var strip: Node = tiles_root.get_node_or_null(SIDE_STRIP_NAMES[index])
		if strip == null:
			continue
		for tile_name in STRIP_TILE_ORDER:
			var tile: Node = strip.get_node_or_null(tile_name)
			if tile is Node3D:
				tiles_list.append(tile)

	for tile_name in ["CornerTile", "Tile2", "Tile3"]:
		var tile: Node = strip1.get_node_or_null(tile_name)
		if tile is Node3D:
			tiles_list.append(tile)

	return tiles_list
