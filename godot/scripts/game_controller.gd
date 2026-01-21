extends Node

@export var game_state_path: NodePath = NodePath("../GameState")
@export var right_sidebar_path: NodePath = NodePath("../Control/MarginContainer/RightSidebar")
@export var left_sidebar_list_path: NodePath = NodePath("../Control/MarginContainer/LeftSidebar/VBoxContainer")
@export var board_layout_path: NodePath = NodePath("../BoardLayout")
@export var pawns_root_path: NodePath = NodePath("../Pawns")

var game_state: GameState = null
var right_sidebar: RightSidebar = null
var left_sidebar_list: Node = null
var board_layout: Node = null
var pawns_root: Node = null

func _ready() -> void:
	game_state = get_node_or_null(game_state_path) as GameState
	right_sidebar = get_node_or_null(right_sidebar_path) as RightSidebar
	left_sidebar_list = get_node_or_null(left_sidebar_list_path)
	board_layout = get_node_or_null(board_layout_path)
	pawns_root = get_node_or_null(pawns_root_path)

	if game_state != null:
		game_state.reset_positions()
		game_state.player_changed.connect(_on_player_changed)
		_apply_player_visibility(game_state.player_count)
		_on_player_changed(game_state.current_player_index)
		_place_all_pawns_at_start()
		_update_tile_info(0)

	call_deferred("_bind_sidebar")

func _bind_sidebar() -> void:
	if right_sidebar == null:
		return
	if right_sidebar.end_turn_button == null:
		return
	if not right_sidebar.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		right_sidebar.end_turn_button.pressed.connect(_on_end_turn_pressed)
	if not right_sidebar.dice_rolled.is_connected(_on_dice_rolled):
		right_sidebar.dice_rolled.connect(_on_dice_rolled)

func _on_end_turn_pressed() -> void:
	if game_state == null:
		return
	game_state.advance_turn()

func _on_player_changed(new_index: int) -> void:
	if right_sidebar == null:
		return
	right_sidebar.set_current_player(new_index)

func _on_dice_rolled(_die_1: int, _die_2: int, total: int) -> void:
	if game_state == null or board_layout == null:
		return
	if not board_layout.has_method("get_board_tiles"):
		return
	var board_tiles: Array = board_layout.get_board_tiles()
	if board_tiles.size() == 0:
		return
	var move_result: Dictionary = game_state.move_player(
		game_state.current_player_index,
		total,
		board_tiles.size()
	)
	if not move_result.has("tile_index"):
		return
	_place_pawn(
		game_state.current_player_index,
		move_result["tile_index"],
		move_result["slot_index"]
	)
	_update_tile_info(move_result["tile_index"])

func _update_tile_info(tile_index: int) -> void:
	if right_sidebar == null or board_layout == null:
		return
	if not board_layout.has_method("get_tile_info"):
		return
	var info: Dictionary = board_layout.get_tile_info(tile_index)
	var tile_type: String = info.get("type", "unknown")
	var city: String = info.get("city", "")
	var incident_kind: String = info.get("incident_kind", "")
	right_sidebar.update_tile_info(tile_type, city, incident_kind)

func _place_all_pawns_at_start() -> void:
	if game_state == null:
		return
	for index in range(game_state.player_count):
		_place_pawn(index, 0, index)

func _apply_player_visibility(count: int) -> void:
	if left_sidebar_list != null:
		for index in range(left_sidebar_list.get_child_count()):
			var child: Node = left_sidebar_list.get_child(index)
			child.visible = index < count
	if pawns_root != null:
		for index in range(1, 7):
			var pawn: Node = pawns_root.get_node_or_null("Pawn%d" % index)
			if pawn != null:
				pawn.visible = index <= count

func _place_pawn(player_index: int, tile_index: int, slot_index: int) -> void:
	if board_layout == null or pawns_root == null:
		return
	if not board_layout.has_method("get_tile_markers"):
		return
	var markers: Array = board_layout.get_tile_markers(tile_index)
	if markers.size() == 0:
		return
	var clamped_slot: int = clamp(slot_index, 0, markers.size() - 1)
	var marker: Marker3D = markers[clamped_slot]
	var pawn: Node3D = pawns_root.get_node_or_null("Pawn%d" % (player_index + 1))
	if pawn == null:
		return
	pawn.global_transform = marker.global_transform
