extends Node

@export var right_sidebar_path: NodePath = NodePath("../Control/MarginContainer/RightSidebar")
@export var left_sidebar_list_path: NodePath = NodePath("../Control/MarginContainer/LeftSidebar/VBoxContainer")
@export var pawns_root_path: NodePath = NodePath("../Pawns")

# TODO: review the methods of thid board layout, it looks like they should be processed once in the beginning and then be part of the game state until the end of the match
@onready var board_layout: Node = %BoardLayout
@onready var game_state: GameState = %GameState

var right_sidebar: RightSidebar = null
var left_sidebar_list: Node = null
var game_id_label: Label = null
var pawns_root: Node = null
var turn_duration: float = 30.0
var turn_elapsed: float = 0.0
var turn_timer_active: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	right_sidebar = get_node_or_null(right_sidebar_path) as RightSidebar
	left_sidebar_list = get_node_or_null(left_sidebar_list_path)
	game_id_label = get_node_or_null("%GameIdLabel") as Label
	pawns_root = get_node_or_null(pawns_root_path)
	_sync_turn_duration()
	_update_game_id_label()

	if game_state != null:
		game_state.reset_positions()
		game_state.player_changed.connect(_on_player_changed)
		_apply_player_visibility(game_state.player_count)
		_on_player_changed(game_state.current_player_index)
		_place_all_pawns_at_start()
		_update_tile_info(0)

	call_deferred("_bind_sidebar")
	set_process(true)

func _bind_sidebar() -> void:
	if right_sidebar == null:
		return
	if right_sidebar.end_turn_button == null:
		return
	if not right_sidebar.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		right_sidebar.end_turn_button.pressed.connect(_on_end_turn_pressed)
	if not right_sidebar.dice_requested.is_connected(_on_dice_requested):
		right_sidebar.dice_requested.connect(_on_dice_requested)
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
	_reset_turn_timer()

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

func _on_dice_requested() -> void:
	if right_sidebar == null:
		return
	var die_1: int = rng.randi_range(1, 6)
	var die_2: int = rng.randi_range(1, 6)
	right_sidebar.apply_dice_result(die_1, die_2)

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
		var summary_index: int = 0
		for child in left_sidebar_list.get_children():
			if child is FoldableContainer:
				child.visible = summary_index < count
				summary_index += 1
	if pawns_root != null:
		for index in range(1, 7):
			var pawn: Node = pawns_root.get_node_or_null("Pawn%d" % index)
			if pawn != null:
				pawn.visible = index <= count

func _process(delta: float) -> void:
	if not turn_timer_active:
		return
	if turn_duration <= 0.0:
		return
	turn_elapsed += delta
	if right_sidebar != null:
		right_sidebar.set_turn_timer(turn_duration, turn_elapsed)
	if turn_elapsed >= turn_duration:
		turn_timer_active = false
		_on_end_turn_pressed()

func _reset_turn_timer() -> void:
	turn_elapsed = 0.0
	turn_timer_active = true
	if right_sidebar != null:
		right_sidebar.set_turn_timer(turn_duration, turn_elapsed)

func _sync_turn_duration() -> void:
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null:
		return
	if config.has_method("get"):
		var new_duration: float = float(config.get("turn_duration"))
		if new_duration > 0.0:
			turn_duration = new_duration
		var game_id: String = str(config.get("game_id"))
		_seed_rng(game_id)

func _update_game_id_label() -> void:
	if game_id_label == null:
		return
	var config: Node = get_node_or_null("/root/GameConfig")
	if config == null or not config.has_method("get"):
		return
	var game_id: String = str(config.get("game_id"))
	game_id_label.text = "Game ID: %s" % game_id

func _seed_rng(game_id: String) -> void:
	if game_id.is_empty():
		rng.randomize()
		return
	rng.seed = _hash_string_to_seed(game_id)

func _hash_string_to_seed(value: String) -> int:
	var hash: int = 0
	for code in value.to_utf8_buffer():
		hash = int((hash * 131) + int(code)) & 0x7fffffff
	return hash

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
