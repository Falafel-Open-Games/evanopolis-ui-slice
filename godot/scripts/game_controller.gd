class_name GameController
extends Node

signal dices_rolled(dice_1: int, dice_2: int, total: int)
signal pawn_move_started(start_tile_index: int, end_tile_index: int, player_index: int)
signal pawn_move_finished(end_tile_index: int, player_index: int)
signal property_purchased(tile_index: int)
signal turn_ended(next_player_index: int, next_tile_index: int)
signal turn_started(player_index: int, tile_index: int)
signal timer_elapsed(turn_duration: int, time_elapsed: float)

# @export var turn_actions: TurnActions
@export var left_sidebar_list: BoxContainer
@export var pawns_root: Node3D
@export var pawn_movement_peak: Vector2 = Vector2(0.15, 0.15)
@export var pawn_jump_height: float = 0.05
@export var pawn_wait_time_per_tile: float = 0.3
@export var pawn_delay_start_movement: float = 0.8

@export var ui_controller : UiController

# TODO: review the methods of thid board layout, it looks like they should be processed once in the beginning and then be part of the game state until the end of the match
@onready var board_layout: Node = %BoardLayout
@onready var game_state: GameState = %GameState
@onready var game_id_label: LineEdit = %GameIdLabel
@onready var build_id_label: Label = %BuildIdLabel

var turn_elapsed: float = 0.0
var turn_timer_active: bool = false
var current_tile_index: int = 0
var pending_toll_owner_index: int = -1
var pending_toll_fiat: float = 0.0
var last_cycle: int = -1
var _pawn_move_token: int = 0
var _pawn_move_tween: Tween = null
var _pawn_jump_tween: Tween = null
var _pawn_move_timer: SceneTreeTimer = null

func _ready() -> void:
    assert(game_state)
    # assert(turn_actions)
    assert(left_sidebar_list)
    assert(game_id_label)
    assert(build_id_label)
    assert(pawns_root)
    # await turn_actions.ready
    _bind_game_state()
    _bind_ui_controller()
    game_id_label.text = "Game ID: %s" % GameConfig.game_id
    build_id_label.text = "Build ID: %s" % GameConfig.build_id
    _apply_player_visibility(GameConfig.player_count)
    _bind_player_summaries()
    call_deferred("_initialize_game_state")

    # call_deferred("_bind_sidebar")
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

func _bind_ui_controller() -> void:
    if not ui_controller.end_turn_button_pressed.is_connected(_on_end_turn_pressed):
        ui_controller.end_turn_button_pressed.connect(_on_end_turn_pressed)
    if not ui_controller.roll_dice_button_pressed.is_connected(_on_roll_dice_pressed):
        ui_controller.roll_dice_button_pressed.connect(_on_roll_dice_pressed)
    if not ui_controller.dice_result_shown.is_connected(_on_dice_result_shown):
        ui_controller.dice_result_shown.connect(_on_dice_result_shown)
    if not ui_controller.buy_property_button_pressed.is_connected(_on_buy_requested):
        ui_controller.buy_property_button_pressed.connect(_on_buy_requested)


# func _bind_sidebar() -> void:
# 	if not turn_actions.end_turn_button.pressed.is_connected(_on_end_turn_pressed):
# 		turn_actions.end_turn_button.pressed.connect(_on_end_turn_pressed)
# 	if not turn_actions.dice_requested.is_connected(_on_dice_requested):
# 		turn_actions.dice_requested.connect(_on_dice_requested)
# 	if not turn_actions.dice_rolled.is_connected(_on_dice_rolled):
# 		turn_actions.dice_rolled.connect(_on_dice_rolled)
# 	if not turn_actions.buy_requested.is_connected(_on_buy_requested):
# 		turn_actions.buy_requested.connect(_on_buy_requested)
# 	if not turn_actions.toll_payment_requested.is_connected(_on_toll_payment_requested):
# 		turn_actions.toll_payment_requested.connect(_on_toll_payment_requested)

func _on_end_turn_pressed() -> void:
    assert(game_state)
    _force_complete_turn_visuals()
    var next_index: int = (game_state.current_player_index + 1) % GameConfig.player_count
    var next_tile_index: int = game_state.player_positions[next_index]
    turn_ended.emit(next_index, next_tile_index)
    game_state.apply_all_pending_miner_orders()
    game_state.advance_turn()

func _on_roll_dice_pressed() -> void:
    _on_dice_requested()

func _on_dice_result_shown(dice_1: int, dice_2: int, total: int) -> void:
    move_player(dice_1, dice_2, total)

func _on_player_changed(new_index: int) -> void:
    # turn_actions.set_current_player(new_index, game_state.turn_count, game_state.current_cycle)
    _reset_turn_timer()
    var tile_index: int = game_state.player_positions[new_index]
    turn_started.emit(new_index, tile_index)

# func _on_dice_rolled(_die_1: int, _die_2: int, total: int) -> void:
func move_player(_dice_1: int, _dice_2: int, total: int) -> void:
    assert(game_state)
    assert(board_layout)
    assert(board_layout.has_method("get_board_tiles"))
    var board_tiles: Array = board_layout.get_board_tiles()
    assert(board_tiles.size() > 0)
    var player_index: int = game_state.current_player_index
    var start_tile_index: int = game_state.player_positions[player_index]
    var target_tile_index: int = (start_tile_index + total) % board_tiles.size()
    pawn_move_started.emit(start_tile_index, target_tile_index, player_index)
    game_state.move_player(
        player_index,
        total,
        board_tiles.size()
    )

func _on_player_position_changed(tile_index: int, slot_index: int) -> void:
    current_tile_index = tile_index
    _place_pawn(
        game_state.current_player_index,
        tile_index,
        slot_index,
        true
    )
    game_state.apply_property_payout(tile_index)
    _update_tile_info(tile_index)

func _on_dice_requested() -> void:
    var dice_1: int = randi_range(1, 6)
    var dice_2: int = randi_range(1, 6)
    dices_rolled.emit(dice_1, dice_2, dice_1 + dice_2)

func _update_tile_info(tile_index: int) -> void:
    assert(game_state)
    var info: TileInfo = game_state.get_tile_info(tile_index)
    var tile_type: Utils.TileType = info.tile_type
    var city: String = info.city
    var incident_kind: String = info.incident_kind
    var price: float = 0.0
    if tile_type == Utils.TileType.PROPERTY:
        price = game_state.get_tile_price(info)
    elif tile_type == Utils.TileType.SPECIAL_PROPERTY:
        price = game_state.get_tile_price(info)
    var buy_visible: bool = (
        (tile_type == Utils.TileType.PROPERTY or tile_type == Utils.TileType.SPECIAL_PROPERTY)
        and info.owner_index == -1
    )
    var is_owned: bool = info.owner_index != -1
    var owner_name: String = ""
    var owner_index: int = -1
    if is_owned:
        owner_index = info.owner_index
        owner_name = "Player %d" % (owner_index + 1)
    var buy_enabled: bool = false
    if buy_visible:
        var payer_index: int = game_state.current_player_index
        var fiat_balance: float = game_state.get_player_fiat_balance(payer_index)
        buy_enabled = price > 0.0 and fiat_balance >= price
    # turn_actions.update_tile_info(
    # 	tile_type,
    # 	city,
    # 	incident_kind,
    # 	price,
    # 	info.special_property_name,
    # 	price,
    # 	game_state.get_energy_toll(info),
    # 	game_state.get_payout_per_miner_for_cycle(1),
    # 	info.miner_batches,
    # 	is_owned,
    # 	owner_index,
    # 	owner_name,
    # 	buy_visible,
    # 	buy_enabled
    # )
    _update_toll_actions(info)

func _update_toll_actions(info: TileInfo) -> void:
    # assert(turn_actions)
    assert(game_state)
    pending_toll_owner_index = -1
    pending_toll_fiat = 0.0
    if info.tile_type == Utils.TileType.PROPERTY and info.owner_index != -1:
        if info.owner_index != game_state.current_player_index:
            var toll_amount: float = game_state.get_energy_toll(info)
            var payer_index: int = game_state.current_player_index
            var fiat_balance: float = game_state.get_player_fiat_balance(payer_index)
            var fiat_enabled: bool = fiat_balance >= toll_amount
            pending_toll_owner_index = info.owner_index
            pending_toll_fiat = toll_amount
            # turn_actions.show_toll_actions(toll_amount, fiat_enabled)
            return
    # turn_actions.hide_toll_actions(false)

func _place_all_pawns_at_start() -> void:
    assert(game_state)
    for index in range(GameConfig.player_count):
        _place_pawn(index, 0, index, false)

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
    var summary_index: int = 0
    for child in left_sidebar_list.get_children():
        var summary: PlayerSummary = child as PlayerSummary
        assert(summary)
        if summary_index < GameConfig.player_count:
            summary.set_game_state(game_state)
        summary_index += 1

func _initialize_game_state() -> void:
    game_state.reset_positions()
    for index in range(1, 7):
        var pawn: Node3D = pawns_root.get_node("Pawn%d" % index)
        assert(pawn)
        game_state.set_accent_color(index - 1, pawn.accent_color)
    _on_player_changed(game_state.current_player_index)
    _place_all_pawns_at_start()
    _update_tile_info(0)

func _process(delta: float) -> void:
    if not turn_timer_active:
        return
    turn_elapsed += delta
    # turn_actions.set_turn_timer(GameConfig.turn_duration, turn_elapsed)
    timer_elapsed.emit(GameConfig.turn_duration, turn_elapsed)
    if turn_elapsed >= GameConfig.turn_duration:
        turn_timer_active = false
        _on_end_turn_pressed()

func _reset_turn_timer() -> void:
    turn_elapsed = 0.0
    turn_timer_active = true
    # turn_actions.set_turn_timer(GameConfig.turn_duration, turn_elapsed)

func _place_pawn(
    player_index: int,
    target_tile_index: int,
    slot_index: int,
    emit_finish: bool
) -> void:
    assert(board_layout)
    assert(pawns_root)

    var pawn_name: String = "Pawn%d" % (player_index + 1)
    var pawn: Node3D = pawns_root.get_node(pawn_name)
    assert(pawn, "Pawn node not found: " + pawn_name)

    var pawn_tile_index: int = int(pawn.get_meta("current_tile", target_tile_index))

    pawn.set_meta("current_tile", target_tile_index)

    if pawn_tile_index == target_tile_index:
        var markers: Array[Marker3D] = board_layout.get_tile_markers(target_tile_index)
        assert(markers.size() > 0)
        var clamped_slot: int = clamp(slot_index, 0, markers.size() - 1)
        pawn.global_transform = markers[clamped_slot].global_transform
        if emit_finish:
            pawn_move_finished.emit(target_tile_index, player_index)
        return

    _cancel_pawn_movement()
    var token: int = _pawn_move_token
    # Await for camera movement
    _pawn_move_timer = get_tree().create_timer(pawn_delay_start_movement)
    await _pawn_move_timer.timeout
    if token != _pawn_move_token:
        return
    _pawn_move_timer = null

    var board_size: int = board_layout.board_size

    var steps_needed: int = (target_tile_index - pawn_tile_index + board_size) % board_size

    for i in range(1, steps_needed + 1):
        if token != _pawn_move_token:
            return
        var next_index: int = (pawn_tile_index + i) % board_size

        var target_slot: int = slot_index if next_index == target_tile_index else 0

        var markers: Array[Marker3D] = board_layout.get_tile_markers(next_index)
        assert(markers.size() > 0)

        var clamped_slot: int = clamp(target_slot, 0, markers.size() - 1)
        var target_marker: Marker3D = markers[clamped_slot]

        _pawn_move_tween = create_tween()
        _pawn_move_tween.set_trans(Tween.TRANS_SINE)
        _pawn_move_tween.set_ease(Tween.EASE_IN_OUT)

        _pawn_move_tween.tween_property(
            pawn,
            "global_position",
            target_marker.global_position,
            pawn_wait_time_per_tile
        )
        _pawn_move_tween.parallel().tween_property(
            pawn,
            "global_rotation",
            target_marker.global_rotation,
            pawn_wait_time_per_tile
        )

        var peak_y: float = target_marker.global_position.y + pawn_jump_height
        var base_y: float = target_marker.global_position.y

        _pawn_jump_tween = create_tween()
        _pawn_jump_tween.tween_property(
            pawn,
            "global_position:y",
            peak_y,
            pawn_movement_peak.y
        ).set_ease(Tween.EASE_OUT)
        _pawn_jump_tween.tween_property(
            pawn,
            "global_position:y",
            base_y,
            pawn_movement_peak.x
        ).set_ease(Tween.EASE_IN)

        await _pawn_move_tween.finished
        if token != _pawn_move_token:
            return
        _pawn_move_tween = null
        _pawn_jump_tween = null
    if emit_finish:
        pawn_move_finished.emit(target_tile_index, player_index)

func _force_complete_turn_visuals() -> void:
    assert(game_state)
    _cancel_pawn_movement()
    _snap_pawn_to_tile(
        game_state.current_player_index,
        game_state.player_positions[game_state.current_player_index]
    )

func _snap_pawn_to_tile(player_index: int, tile_index: int) -> void:
    assert(board_layout)
    assert(pawns_root)
    assert(game_state)
    var pawn_name: String = "Pawn%d" % (player_index + 1)
    var pawn: Node3D = pawns_root.get_node(pawn_name)
    assert(pawn, "Pawn node not found: " + pawn_name)
    var markers: Array[Marker3D] = board_layout.get_tile_markers(tile_index)
    assert(markers.size() > 0)
    var occupants: Array[int] = game_state.tiles[tile_index].occupants
    var slot_index: int = occupants.find(player_index)
    assert(slot_index >= 0 and slot_index < markers.size())
    pawn.set_meta("current_tile", tile_index)
    pawn.global_transform = markers[slot_index].global_transform

func _cancel_pawn_movement() -> void:
    _pawn_move_token += 1
    if _pawn_move_tween:
        _pawn_move_tween.kill()
        _pawn_move_tween = null
    if _pawn_jump_tween:
        _pawn_jump_tween.kill()
        _pawn_jump_tween = null
    if _pawn_move_timer:
        _pawn_move_timer = null

func _on_buy_requested() -> void:
    assert(game_state)
    var did_purchase: bool = game_state.purchase_tile(
        game_state.current_player_index,
        current_tile_index,
        false
    )
    assert(did_purchase)
    _flip_tile(current_tile_index)
    _update_tile_info(current_tile_index)
    property_purchased.emit(current_tile_index)

func _on_toll_payment_requested() -> void:
    assert(game_state)
    # assert(turn_actions)
    if pending_toll_owner_index == -1:
        return
    var did_pay: bool = game_state.pay_energy_toll(
        game_state.current_player_index,
        pending_toll_owner_index,
        pending_toll_fiat,
        false
    )
    if not did_pay:
        var info: TileInfo = game_state.get_tile_info(current_tile_index)
        _update_toll_actions(info)
        return
    pending_toll_owner_index = -1
    pending_toll_fiat = 0.0
    # turn_actions.hide_toll_actions(true)

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
    # turn_actions.set_turn_state(turn_number, cycle_number)
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
    assert(not board_tiles.is_empty())
    var start_tile: Node3D = board_tiles[0]
    var board_tile: BoardTile = start_tile as BoardTile
    assert(board_tile != null)
    var is_inflation: bool = cycle_number % 2 == 0
    board_tile.set_owned_visual(is_inflation)
