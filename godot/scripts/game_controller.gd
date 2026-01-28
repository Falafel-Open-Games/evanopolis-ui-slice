class_name GameController
extends Node

@export var turn_actions: TurnActions
@export var left_sidebar_list: VBoxContainer
@export var pawns_root: Node3D
@export var pawn_movement_peak: Vector2 = Vector2(0.15, 0.15)
@export var pawn_jump_height: float = 0.05
@export var pawn_wait_time_per_tile: float = 0.3
@export var pawn_delay_start_movement: float = 0.8

# TODO: review the methods of thid board layout, it looks like they should be processed once in the beginning and then be part of the game state until the end of the match
@onready var board_layout: Node = %BoardLayout
@onready var game_state: GameState = %GameState
@onready var game_id_label: Label = %GameIdLabel
@onready var build_id_label: Label = %BuildIdLabel

var turn_elapsed: float = 0.0
var turn_timer_active: bool = false
var current_tile_index: int = 0
var pending_toll_owner_index: int = -1
var pending_toll_fiat: float = 0.0
var pending_toll_btc: float = 0.0
var last_cycle: int = -1

func _ready() -> void:
	assert(game_state)
	assert(turn_actions)
	assert(left_sidebar_list)
	assert(game_id_label)
	assert(build_id_label)
	assert(pawns_root)
	await turn_actions.ready
	_bind_game_state()
	game_id_label.text = "Game ID: %s" % GameConfig.game_id
	build_id_label.text = "Build ID: %s" % GameConfig.build_id
	_apply_player_visibility(GameConfig.player_count)
	_bind_player_summaries()
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
	if not game_state.player_data_changed.is_connected(_on_player_data_changed):
		game_state.player_data_changed.connect(_on_player_data_changed)
	if not game_state.turn_state_changed.is_connected(_on_turn_state_changed):
		game_state.turn_state_changed.connect(_on_turn_state_changed)
	if not game_state.miner_batches_changed.is_connected(_on_miner_batches_changed):
		game_state.miner_batches_changed.connect(_on_miner_batches_changed)

func _bind_sidebar() -> void:
	if not turn_actions.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		turn_actions.end_turn_button.pressed.connect(_on_end_turn_pressed)
	if not turn_actions.dice_requested.is_connected(_on_dice_requested):
		turn_actions.dice_requested.connect(_on_dice_requested)
	if not turn_actions.dice_rolled.is_connected(_on_dice_rolled):
		turn_actions.dice_rolled.connect(_on_dice_rolled)
	if not turn_actions.buy_requested.is_connected(_on_buy_requested):
		turn_actions.buy_requested.connect(_on_buy_requested)
	if not turn_actions.toll_payment_requested.is_connected(_on_toll_payment_requested):
		turn_actions.toll_payment_requested.connect(_on_toll_payment_requested)

func _on_end_turn_pressed() -> void:
	assert(game_state)
	game_state.apply_all_pending_miner_orders()
	game_state.advance_turn()

func _on_player_changed(new_index: int) -> void:
	turn_actions.set_current_player(new_index, game_state.turn_count, game_state.current_cycle)
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
func _on_player_position_changed(tile_index: int, slot_index: int) -> void:
	current_tile_index = tile_index
	_place_pawn(
		game_state.current_player_index,
		tile_index,
		slot_index
	)
	_update_tile_info(tile_index)

func _on_dice_requested() -> void:
	assert(turn_actions)
	var die_1: int = randi_range(1, 6)
	var die_2: int = randi_range(1, 6)
	turn_actions.apply_dice_result(die_1, die_2)

func _update_tile_info(tile_index: int) -> void:
	assert(game_state)
	var info: TileInfo = game_state.get_tile_info(tile_index)
	var tile_type: String = info.tile_type
	var city: String = info.city
	var incident_kind: String = info.incident_kind
	var price: float = 0.0
	if tile_type == "property":
		price = game_state.get_tile_price(info)
	elif tile_type == "special_property":
		price = game_state.get_tile_price(info)
	var buy_visible: bool = (
		(tile_type == "property" or tile_type == "special_property")
		and info.owner_index == -1
	)
	var is_owned: bool = info.owner_index != -1
	var owner_name: String = ""
	var owner_index: int = -1
	if is_owned:
		owner_index = info.owner_index
		owner_name = "Player %d" % (owner_index + 1)
	var buy_enabled: bool = false
	var buy_btc_enabled: bool = false
	if buy_visible:
		var payer_index: int = game_state.current_player_index
		var fiat_balance: float = game_state.get_player_fiat_balance(payer_index)
		var btc_balance: float = game_state.get_player_bitcoin_balance(payer_index)
		var price_btc: float = game_state.get_tile_price_btc(info)
		buy_enabled = price > 0.0 and fiat_balance >= price
		buy_btc_enabled = price_btc > 0.0 and btc_balance >= price_btc
	turn_actions.update_tile_info(
		tile_type,
		city,
		incident_kind,
		price,
		info.special_property_name,
		price,
		game_state.get_tile_price_btc(info),
		game_state.get_energy_toll(info),
		game_state.get_energy_toll_btc(info),
		game_state.get_payout_per_miner_for_cycle(1),
		game_state.get_payout_per_miner_for_cycle(3),
		info.miner_batches,
		is_owned,
		owner_index,
		owner_name,
		buy_visible,
		buy_enabled,
		buy_btc_enabled
	)
	_update_toll_actions(info)

func _update_toll_actions(info: TileInfo) -> void:
	assert(turn_actions)
	assert(game_state)
	pending_toll_owner_index = -1
	pending_toll_fiat = 0.0
	pending_toll_btc = 0.0
	if info.tile_type == "property" and info.owner_index != -1:
		if info.owner_index != game_state.current_player_index:
			var toll_amount: float = game_state.get_energy_toll(info)
			var toll_btc: float = game_state.get_energy_toll_btc(info)
			var payer_index: int = game_state.current_player_index
			var fiat_balance: float = game_state.get_player_fiat_balance(payer_index)
			var btc_balance: float = game_state.get_player_bitcoin_balance(payer_index)
			var fiat_enabled: bool = fiat_balance >= toll_amount
			var btc_enabled: bool = btc_balance >= toll_btc
			pending_toll_owner_index = info.owner_index
			pending_toll_fiat = toll_amount
			pending_toll_btc = toll_btc
			turn_actions.show_toll_actions(toll_amount, toll_btc, fiat_enabled, btc_enabled)
			return
	turn_actions.hide_toll_actions(false)

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

func _bind_player_summaries() -> void:
	for child in left_sidebar_list.get_children():
		var summary: PlayerSummary = child as PlayerSummary
		assert(summary)
		summary.set_game_state(game_state)

func _process(delta: float) -> void:
	if not turn_timer_active:
		return
	turn_elapsed += delta
	turn_actions.set_turn_timer(GameConfig.turn_duration, turn_elapsed)
	if turn_elapsed >= GameConfig.turn_duration:
		turn_timer_active = false
		_on_end_turn_pressed()

func _reset_turn_timer() -> void:
	turn_elapsed = 0.0
	turn_timer_active = true
	turn_actions.set_turn_timer(GameConfig.turn_duration, turn_elapsed)

func _place_pawn(player_index: int, target_tile_index: int, slot_index: int) -> void:
	assert(board_layout)
	assert(pawns_root)

	var pawn_name: String = "Pawn%d" % (player_index + 1)
	var pawn: Node3D = pawns_root.get_node(pawn_name)
	assert(pawn, "Pawn node not found: " + pawn_name)

	var current_tile_index: int = int(pawn.get_meta("current_tile", target_tile_index))

	pawn.set_meta("current_tile", target_tile_index)

	if current_tile_index == target_tile_index:
		var markers: Array[Marker3D] = board_layout.get_tile_markers(target_tile_index)
		assert(markers.size() > 0)
		var clamped_slot: int = clamp(slot_index, 0, markers.size() - 1)
		pawn.global_transform = markers[clamped_slot].global_transform
		return

	# Await for camera movement
	await get_tree().create_timer(pawn_delay_start_movement).timeout

	var board_size: int = board_layout.board_size

	var steps_needed: int = (target_tile_index - current_tile_index + board_size) % board_size

	for i in range(1, steps_needed + 1):
		var next_index: int = (current_tile_index + i) % board_size

		var target_slot: int = slot_index if next_index == target_tile_index else 0

		var markers: Array[Marker3D] = board_layout.get_tile_markers(next_index)
		assert(markers.size() > 0)

		var clamped_slot: int = clamp(target_slot, 0, markers.size() - 1)
		var target_marker: Marker3D = markers[clamped_slot]

		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(pawn, "global_position", target_marker.global_position, pawn_wait_time_per_tile)
		tween.parallel().tween_property(pawn, "global_rotation", target_marker.global_rotation, pawn_wait_time_per_tile)

		var peak_y: float = target_marker.global_position.y + pawn_jump_height
		var base_y: float = target_marker.global_position.y

		var jump_tween: Tween = create_tween()
		jump_tween.tween_property(pawn, "global_position:y", peak_y, pawn_movement_peak.y).set_ease(Tween.EASE_OUT)
		jump_tween.tween_property(pawn, "global_position:y", base_y, pawn_movement_peak.x).set_ease(Tween.EASE_IN)

		await tween.finished

func _on_buy_requested(use_bitcoin: bool) -> void:
	assert(game_state)
	var did_purchase: bool = game_state.purchase_tile(
		game_state.current_player_index,
		current_tile_index,
		use_bitcoin
	)
	assert(did_purchase)
	_flip_tile(current_tile_index)
	_update_tile_info(current_tile_index)

func _on_toll_payment_requested(use_bitcoin: bool) -> void:
	assert(game_state)
	assert(turn_actions)
	if pending_toll_owner_index == -1:
		return
	var did_pay: bool = game_state.pay_energy_toll(
		game_state.current_player_index,
		pending_toll_owner_index,
		pending_toll_btc if use_bitcoin else pending_toll_fiat,
		use_bitcoin
	)
	if not did_pay:
		var info: TileInfo = game_state.get_tile_info(current_tile_index)
		_update_toll_actions(info)
		return
	pending_toll_owner_index = -1
	pending_toll_fiat = 0.0
	pending_toll_btc = 0.0
	turn_actions.hide_toll_actions(true)

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

func _on_player_data_changed(player_index: int, player_data: PlayerData) -> void:
	assert(player_index >= 0 and player_index < GameConfig.player_count)
	var summaries: Array = left_sidebar_list.get_children()
	assert(player_index < summaries.size())
	var summary: PlayerSummary = summaries[player_index] as PlayerSummary
	assert(summary)
	summary.set_player_data(player_data)

func _on_turn_state_changed(_player_index: int, turn_number: int, cycle_number: int) -> void:
	turn_actions.set_turn_state(turn_number, cycle_number)
	if cycle_number != last_cycle:
		_update_cycle_visual(cycle_number)
		last_cycle = cycle_number

func _on_miner_batches_changed(tile_index: int, miner_batches: int, owner_index: int) -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	var board_tiles: Array = board_layout.get_board_tiles()
	assert(tile_index >= 0 and tile_index < board_tiles.size())
	var tile: Node3D = board_tiles[tile_index]
	var board_tile: BoardTile = tile as BoardTile
	assert(board_tile)
	if owner_index < 0:
		board_tile.set_miner_batches(0, Color.WHITE)
		return
	var owner_color: Color = Palette.get_player_light(owner_index)
	board_tile.set_miner_batches(miner_batches, owner_color)

func _update_cycle_visual(cycle_number: int) -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	var board_tiles: Array = board_layout.get_board_tiles()
	if board_tiles.is_empty():
		return
	var start_tile: Node3D = board_tiles[0]
	var board_tile: BoardTile = start_tile as BoardTile
	if board_tile == null:
		return
	var is_inflation: bool = cycle_number % 2 == 0
	board_tile.set_owned_visual(is_inflation)
