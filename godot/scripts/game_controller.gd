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
var current_tile_index: int = 0

func _ready() -> void:
	assert(game_state)
	assert(right_sidebar)
	assert(left_sidebar_list)
	assert(game_id_label)
	assert(build_id_label)
	assert(pawns_root)
	await right_sidebar.ready
	_bind_game_state()
	game_id_label.text = "Game ID: %s" % GameConfig.game_id
	build_id_label.text = "Build ID: %s" % GameConfig.build_id
	_apply_player_visibility(GameConfig.player_count)
	_on_player_changed(game_state.current_player_index)
	game_state.reset_positions()
	_place_all_pawns_at_start()
	_update_tile_info(0)

	call_deferred("_bind_sidebar")
	set_process(true)

func _bind_game_state() -> void:
	if not game_state.player_changed.is_connected(_on_player_changed):
		game_state.player_changed.connect(_on_player_changed)
	if not game_state.player_position_changed.is_connected(_on_player_position_changed):
		game_state.player_position_changed.connect(_on_player_position_changed)
	if not game_state.balance_changed.is_connected(_on_balance_changed):
		game_state.balance_changed.connect(_on_balance_changed)

func _bind_sidebar() -> void:
	if not right_sidebar.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		right_sidebar.end_turn_button.pressed.connect(_on_end_turn_pressed)
	if not right_sidebar.dice_requested.is_connected(_on_dice_requested):
		right_sidebar.dice_requested.connect(_on_dice_requested)
	if not right_sidebar.dice_rolled.is_connected(_on_dice_rolled):
		right_sidebar.dice_rolled.connect(_on_dice_rolled)
	if not right_sidebar.buy_pressed.is_connected(_on_buy_pressed):
		right_sidebar.buy_pressed.connect(_on_buy_pressed)

func _on_end_turn_pressed() -> void:
	assert(game_state)
	game_state.advance_turn()

func _on_player_changed(new_index: int) -> void:
	right_sidebar.set_current_player(new_index)
	_reset_turn_timer()

func _on_dice_rolled(_die_1: int, _die_2: int, total: int) -> void:
	assert(game_state)
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	var board_tiles: Array = board_layout.get_board_tiles()
	assert(board_tiles.size() > 0)
	game_state.move_player(
		game_state.current_player_index,
		total,
		board_tiles.size()
	)
func _on_player_position_changed(tile_index, slot_index):
	current_tile_index = tile_index
	_place_pawn(
		game_state.current_player_index,
		tile_index,
		slot_index
	)
	_update_tile_info(tile_index)

func _on_dice_requested() -> void:
	assert(right_sidebar)
	var die_1: int = randi_range(1, 6)
	var die_2: int = randi_range(1, 6)
	right_sidebar.apply_dice_result(die_1, die_2)

func _update_tile_info(tile_index: int) -> void:
	assert(game_state)
	var info: TileInfo = game_state.get_tile_info(tile_index)
	var tile_type: String = info.tile_type
	var city: String = info.city
	var incident_kind: String = info.incident_kind
	var price: float = 0.0
	if tile_type == "property":
		price = info.property_price
	elif tile_type == "special_property":
		price = info.special_property_price
	var buy_visible: bool = (
		(tile_type == "property" or tile_type == "special_property")
		and info.owner_index == -1
	)
	var is_owned: bool = info.owner_index != -1
	var owner_name: String = ""
	if is_owned:
		owner_name = "Player %d" % (info.owner_index + 1)
	var buy_enabled: bool = false
	if buy_visible:
		var balance: float = game_state.get_player_balance(game_state.current_player_index)
		buy_enabled = price > 0.0 and balance >= price
	right_sidebar.update_tile_info(
		tile_type,
		city,
		incident_kind,
		info.property_price,
		info.special_property_name,
		info.special_property_price,
		is_owned,
		owner_name,
		buy_visible,
		buy_enabled
	)

func _place_all_pawns_at_start() -> void:
	assert(game_state)
	for index in range(GameConfig.player_count):
		_place_pawn(index, 0, index)

func _apply_player_visibility(count: int) -> void:
	var summary_index: int = 0
	for child in left_sidebar_list.get_children():
		var summary: PlayerSummary = child as PlayerSummary
		assert(summary)
		summary.visible = summary_index < count
		summary_index += 1
	for index in range(1, 7):
		var pawn: Node3D = pawns_root.get_node("Pawn%d" % index)
		assert(pawn)
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
	assert(board_layout)
	assert(pawns_root)
	assert(board_layout.has_method("get_tile_markers"))
	var markers: Array = board_layout.get_tile_markers(tile_index)
	assert(markers.size() > 0)
	var clamped_slot: int = clamp(slot_index, 0, markers.size() - 1)
	var marker: Marker3D = markers[clamped_slot]
	var pawn: Node3D = pawns_root.get_node("Pawn%d" % (player_index + 1))
	assert(pawn)
	pawn.global_transform = marker.global_transform

func _on_buy_pressed() -> void:
	assert(game_state)
	var did_purchase: bool = game_state.purchase_tile(
		game_state.current_player_index,
		current_tile_index
	)
	assert(did_purchase)
	_flip_tile(current_tile_index)
	_update_tile_info(current_tile_index)

func _flip_tile(tile_index: int) -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	var board_tiles: Array = board_layout.get_board_tiles()
	assert(tile_index >= 0 and tile_index < board_tiles.size())
	var tile: Node3D = board_tiles[tile_index]
	assert(tile)
	var board_tile: BoardTile = tile as BoardTile
	assert(board_tile)
	board_tile.set_owned_visual(true)

func _on_balance_changed(player_index: int, new_balance: float) -> void:
	assert(player_index >= 0 and player_index < GameConfig.player_count)
	var summaries: Array = left_sidebar_list.get_children()
	assert(player_index < summaries.size())
	var summary: PlayerSummary = summaries[player_index] as PlayerSummary
	assert(summary)
	summary.set_balance(new_balance)
