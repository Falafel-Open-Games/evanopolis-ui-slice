@tool
extends Node

const SIDE_COUNT: int = 6
const SIDE_STRIP_NAMES: Array[String] = [
	"SideStrip1",
	"SideStrip2",
	"SideStrip3",
	"SideStrip4",
	"SideStrip5",
	"SideStrip6",
]

const CORNER_TILE_NAME: String = "CornerTile"
const FIRST_TILE_NAME: String = "Tile2"
const BASE_TILE_OFFSET: float = 0.05173998
const BASE_TILE_SPACING: float = 0.045
const SIDE_LENGTH_FUDGE: float = 0.00152004
const SIDE_TURN_RADIANS: float = 1.0471976

@export_enum("24:24", "30:30", "36:36") var board_size: int = 24:
	set(value):
		board_size = value
		if is_inside_tree():
			_rebuild_board()

@export var side_strip_scene: PackedScene = preload("res://scenes/side_strip.tscn")
@export var tile_scene: PackedScene = preload("res://scenes/tile.tscn")

var _tiles: Array[Node3D] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		if _sync_from_config():
			return
	_rebuild_board()

func _sync_from_config() -> bool:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null:
		return false
	if config.has_method("get"):
		var new_size: int = config.get("board_size")
		if new_size != board_size:
			board_size = new_size
			return true
	return false

func _rebuild_board() -> void:
	_clear_tiles()
	_build_board()
	_apply_colors()

func _clear_tiles() -> void:
	_tiles = []
	var tiles_root: Node = get_node_or_null("../tiles")
	if tiles_root == null:
		return
	for child in tiles_root.get_children():
		tiles_root.remove_child(child)
		child.queue_free()

func _build_board() -> void:
	var tiles_root: Node = get_node_or_null("../tiles")
	if tiles_root == null:
		return
	if board_size % SIDE_COUNT != 0:
		return
	var tiles_per_side: int = board_size / SIDE_COUNT
	if tiles_per_side < 4:
		return
	if side_strip_scene == null:
		return

	var side_length: float = (BASE_TILE_OFFSET * 2.0) + (BASE_TILE_SPACING * float(tiles_per_side - 2)) + SIDE_LENGTH_FUDGE
	var owner: Node = _get_scene_owner()
	var prev_side: Node3D = null

	for side_index in range(SIDE_COUNT):
		var side: Node3D = side_strip_scene.instantiate() as Node3D
		if side == null:
			continue
		side.name = SIDE_STRIP_NAMES[side_index]

		if prev_side == null:
			tiles_root.add_child(side)
		else:
			prev_side.add_child(side)
			side.position = Vector3(side_length, 0.0, 0.0)
			side.rotation = Vector3(0.0, SIDE_TURN_RADIANS, 0.0)

		if owner != null:
			side.owner = owner
		_ensure_side_tiles(side, tiles_per_side, owner)
		prev_side = side

	_rebuild_tile_list(tiles_per_side)

func _ensure_side_tiles(side: Node3D, tiles_per_side: int, owner: Node) -> void:
	var base_tile: Node3D = side.get_node_or_null("Tile4") as Node3D
	if base_tile == null:
		return
	var spacing: float = BASE_TILE_SPACING
	var start_offset: float = BASE_TILE_OFFSET

	for index in range(5, tiles_per_side + 1):
		var tile_name: String = "Tile%d" % index
		var existing: Node = side.get_node_or_null(tile_name)
		if existing != null:
			continue
		if tile_scene == null:
			break
		var tile_instance: Node3D = tile_scene.instantiate() as Node3D
		if tile_instance == null:
			continue
		tile_instance.name = tile_name
		tile_instance.position = Vector3(start_offset + (spacing * float(index - 2)), 0.0, 0.0)
		side.add_child(tile_instance)
		if owner != null:
			tile_instance.owner = owner

func _rebuild_tile_list(tiles_per_side: int) -> void:
	_tiles = []
	var tiles_root: Node = get_node_or_null("../tiles")
	if tiles_root == null:
		return
	for side_index in range(SIDE_COUNT):
		var side_name: String = SIDE_STRIP_NAMES[side_index]
		var side: Node = _get_side_node(tiles_root, side_name)
		if side == null:
			continue
		var tile_names: Array[String] = _get_tile_names_for_side(tiles_per_side)
		for tile_name in tile_names:
			var tile: Node = side.get_node_or_null(tile_name)
			if tile is Node3D:
				_tiles.append(tile)

func _apply_colors() -> void:
	for tile_index in range(_tiles.size()):
		var tile: Node3D = _tiles[tile_index]
		if not tile is BoardTile:
			continue
		var info: Dictionary = get_tile_info(tile_index)
		var tile_type: String = info.get("type", "unknown")
		var tile_color: Color = Color.WHITE
		match tile_type:
			"start":
				tile_color = Color.CORAL
			"inspection":
				tile_color = Color.DIM_GRAY
			"incident":
				tile_color = Color.ORANGE
			"special_property":
				tile_color = Color.WHITE
			"property":
				var city: String = info.get("city", "")
				tile_color = Palette.CITY_COLORS_BY_NAME.get(city, Color.WHITE)
		tile.tile_color = tile_color

func get_board_tiles() -> Array[Node3D]:
	if _tiles.is_empty():
		_rebuild_board()
	return _tiles

func _get_side_node(tiles_root: Node, side_name: String) -> Node:
	if tiles_root == null:
		return null
	var side: Node = tiles_root.get_node_or_null(side_name)
	if side != null:
		return side
	return tiles_root.find_child(side_name, true, false)

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

	var tiles_per_side: int = _get_tiles_per_side()
	if tiles_per_side == 0:
		return info
	if tile_index < 0 or tile_index >= board_size:
		return info

	var side_index: int = tile_index / tiles_per_side
	var side_slot: int = tile_index % tiles_per_side

	if side_slot == 0:
		match side_index:
			0:
				info["type"] = "start"
			3:
				info["type"] = "inspection"
			1, 2, 4, 5:
				info["type"] = "incident"
				info["incident_kind"] = _incident_kind_for_side(side_index)
		return info

	if side_slot == 1:
		info["type"] = "special_property"
		return info

	info["type"] = "property"
	info["city"] = _city_for_side(side_index)
	return info

func _get_tiles_per_side() -> int:
	if board_size % SIDE_COUNT != 0:
		return 0
	return board_size / SIDE_COUNT

func _incident_kind_for_side(side_index: int) -> String:
	match side_index:
		1, 4:
			return "suerte"
		2, 5:
			return "destino"
	return ""

func _city_for_side(side_index: int) -> String:
	if side_index < 0 or side_index >= Palette.CITY_ORDER.size():
		return ""
	return Palette.CITY_ORDER[side_index]

func _get_tile_names_for_side(tiles_per_side: int) -> Array[String]:
	var names: Array[String] = [CORNER_TILE_NAME]
	for index in range(2, tiles_per_side + 1):
		names.append("Tile%d" % index)
	return names

func _get_scene_owner() -> Node:
	if not Engine.is_editor_hint():
		return null
	return get_tree().edited_scene_root
