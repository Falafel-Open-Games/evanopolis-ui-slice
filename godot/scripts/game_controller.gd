class_name GameController
extends Node

@export var right_sidebar: RightSidebar
@export var left_sidebar_list: VBoxContainer
@export var pawns_root: Node3D

# TODO: review the methods of thid board layout, it looks like they should be processed once in the beginning and then be part of the game state until the end of the match
@onready var board_layout: Node = %BoardLayout
@onready var game_state: GameState = %GameState
@onready var game_id_label: Label = %GameIdLabel
@onready var build_id_label: Label = %BuildIdLabel

var turn_elapsed: float = 0.0
var turn_timer_active: bool = false

func _ready() -> void:
	assert(game_state)
	assert(right_sidebar)
	assert(left_sidebar_list)
	assert(game_id_label)
	assert(build_id_label)
	assert(pawns_root)
	game_id_label.text = "Game ID: %s" % GameConfig.game_id
	build_id_label.text = "Build ID: %s" % GameConfig.build_id
	_apply_player_visibility(GameConfig.player_count)
	_on_player_changed(game_state.current_player_index)
	_place_all_pawns_at_start()
	_update_tile_info(0)

	game_state.reset_positions()
	_bind_game_state()
	call_deferred("_bind_sidebar")
	set_process(true)

func _bind_game_state() -> void:
	if not game_state.player_changed.is_connected(_on_player_changed):
		game_state.player_changed.connect(_on_player_changed)
	if not game_state.player_position_changed.is_connected(_on_player_position_changed):
		game_state.player_position_changed.connect(_on_player_position_changed)

func _bind_sidebar() -> void:
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
	game_state.move_player(
		game_state.current_player_index,
		total,
		board_tiles.size()
	)
func _on_player_position_changed(tile_index, slot_index):
	_place_pawn(
		game_state.current_player_index,
		tile_index,
		slot_index
	)
	_update_tile_info(tile_index)

func _on_dice_requested() -> void:
	if right_sidebar == null:
		return
	var die_1: int = randi_range(1, 6)
	var die_2: int = randi_range(1, 6)
	right_sidebar.apply_dice_result(die_1, die_2)

func _update_tile_info(tile_index: int) -> void:
	assert(game_state)
	var info: TileInfo = game_state.get_tile_info(tile_index)
	var tile_type: String = info.tile_type
	var city: String = info.city
	var incident_kind: String = info.incident_kind
	right_sidebar.update_tile_info(
		tile_type,
		city,
		incident_kind,
		info.property_price,
		info.special_property_name,
		info.special_property_price
	)

func _place_all_pawns_at_start() -> void:
	if game_state == null:
		return
	for index in range(GameConfig.player_count):
		_place_pawn(index, 0, index)

func _apply_player_visibility(count: int) -> void:
	var summary_index: int = 0
	for child in left_sidebar_list.get_children():
		if child is FoldableContainer:
			child.visible = summary_index < count
			summary_index += 1
	for index in range(1, 7):
		var pawn: Node = pawns_root.get_node_or_null("Pawn%d" % index)
		if pawn != null:
			pawn.visible = index <= count

func _process(delta: float) -> void:
	if not turn_timer_active:
		return
	turn_elapsed += delta
	right_sidebar.set_turn_timer(GameConfig.turn_duration, turn_elapsed)
	if turn_elapsed >= GameConfig.turn_duration:
		turn_timer_active = false
		_on_end_turn_pressed()

func _reset_turn_timer() -> void:
	turn_elapsed = 0.0
	turn_timer_active = true
	right_sidebar.set_turn_timer(GameConfig.turn_duration, turn_elapsed)

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
