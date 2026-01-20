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

const CENTER_TILE_NAME: String = "Tile3"
const STRIP_TILE_ORDER: Array[String] = [
	"CornerTile",
	"Tile2",
	"Tile3",
	"Tile4",
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

		_set_tile_color(side, "CornerTile", Color.CORAL)
		_set_tile_color(side, "Tile2", prev_color)

		_set_tile_color(side, CENTER_TILE_NAME, Color.WHITE)

		_set_tile_color(side, "Tile4", next_color)

func _set_tile_color(parent: Node, tile_name: String, color: Color) -> void:
	var tile: Node = parent.get_node_or_null(tile_name)
	if tile is BoardTile:
		tile.tile_color = color

func get_board_tiles() -> Array[Node3D]:
	var tiles_list: Array[Node3D] = []
	var tiles_root: Node = get_node_or_null("../tiles")
	if tiles_root == null:
		return tiles_list

	# Start at SideStrip1 Tile3 and move counter-clockwise.
	var strip1: Node = tiles_root.get_node_or_null(SIDE_STRIP_NAMES[0])
	if strip1 == null:
		return tiles_list
	for tile_name in ["Tile3", "Tile4"]:
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

	for tile_name in ["CornerTile", "Tile2"]:
		var tile: Node = strip1.get_node_or_null(tile_name)
		if tile is Node3D:
			tiles_list.append(tile)

	return tiles_list

func get_tile_markers(tile_index: int) -> Array[Marker3D]:
	var tiles: Array[Node3D] = get_board_tiles()
	if tile_index < 0 or tile_index >= tiles.size():
		return []
	var tile: Node3D = tiles[tile_index]
	var markers_root: Node = tile.get_node_or_null("PawnMarkers")
	if markers_root == null:
		return []
	var markers: Array[Marker3D] = []
	for index in range(1, 7):
		var marker_node: Node = markers_root.get_node_or_null("Marker%d" % index)
		if marker_node is Marker3D:
			markers.append(marker_node)
	return markers

func get_tile_info(tile_index: int) -> Dictionary:
	var info: Dictionary = {
		"type": "unknown",
		"city": "",
		"incident_kind": "",
	}

	if tile_index == 0:
		info["type"] = "start"
		return info
	if tile_index == 12:
		info["type"] = "inspection"
		return info
	if tile_index == 4 or tile_index == 16:
		info["type"] = "incident"
		info["incident_kind"] = "suerte"
		return info
	if tile_index == 8 or tile_index == 20:
		info["type"] = "incident"
		info["incident_kind"] = "destino"
		return info

	info["type"] = "special_property" if _is_corner_tile(tile_index) else "property"

	var city: String = _city_for_property(tile_index)
	if city.is_empty():
		return info
	info["city"] = city
	return info

func _is_corner_tile(tile_index: int) -> bool:
	var corners: Array[int] = [2, 6, 10, 14, 18, 22]
	print("is corner", corners, tile_index, corners.has(tile_index))
	return corners.has(tile_index)

func _city_for_property(tile_index: int) -> String:
	if tile_index == 1 or tile_index == 3:
		return Palette.CITY_ORDER[0]
	if tile_index == 5  or tile_index == 7:
		return Palette.CITY_ORDER[1]
	if tile_index == 9 or tile_index == 11:
		return Palette.CITY_ORDER[2]
	if tile_index == 13 or tile_index == 15:
		return Palette.CITY_ORDER[3]
	if tile_index == 17 or tile_index == 19:
		return Palette.CITY_ORDER[4]
	if tile_index == 21 or tile_index == 23:
		return Palette.CITY_ORDER[5]
	return ""
