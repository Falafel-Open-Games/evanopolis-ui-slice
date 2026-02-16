class_name UiController
extends Node

signal end_turn_button_pressed
signal roll_dice_button_pressed
signal dice_result_shown(dice_1: int, dice_2: int, total: int)

@export var game_controller: GameController
@export var game_state: GameState

@export var timer_label : Label
@export var player_name : Label
@export var player_balance : Label
@export var player_color : ColorRect
@export var dice_1_label : Label
@export var dice_2_label : Label
@export var end_turn_button : Button
@export var roll_dice_button : Button
@export var card_ui : CardUi

func _ready() -> void:
    # reset UI
    dice_1_label.visible = false
    dice_2_label.visible = false
    end_turn_button.visible = false
    roll_dice_button.visible = false

    # bind states
    _bind_game_state()
    _bind_game_controller()
    _bind_ui_elements()

func _start_game() -> void:
    await get_tree().create_timer(2.0).timeout

    roll_dice_button.visible = true

func _bind_ui_elements() -> void:
    if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
        end_turn_button.pressed.connect(_on_end_turn_button_pressed)
    if not roll_dice_button.pressed.is_connected(_on_roll_dice_button_pressed):
        roll_dice_button.pressed.connect(_on_roll_dice_button_pressed)

func _bind_game_controller() -> void:
    if not game_controller.timer_elapsed.is_connected(_on_timer_elapsed):
        game_controller.timer_elapsed.connect(_on_timer_elapsed)
    if not game_controller.turn_started.is_connected(_on_turn_started):
        game_controller.turn_started.connect(_on_turn_started)
    if not game_controller.turn_ended.is_connected(_on_turn_ended):
        game_controller.turn_ended.connect(_on_turn_ended)
    if not game_controller.dices_rolled.is_connected(_on_dices_rolled):
        game_controller.dices_rolled.connect(_on_dices_rolled)
    if not game_controller.pawn_move_finished.is_connected(_on_pawn_move_finished):
        game_controller.pawn_move_finished.connect(_on_pawn_move_finished)

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

func _on_timer_elapsed(turn_duration: int, time_elapsed: float):
    var remaining := int(max(0.0, turn_duration - time_elapsed))
    var minutes := remaining / 60
    var seconds := remaining % 60
    timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_turn_started(player_index: int, tile_index: int):
    print("_on_turn_started %s %s" % [player_index, tile_index])
    roll_dice_button.visible = true
    player_name.text = game_state.get_player_username(player_index)
    var fiat_balance = game_state.get_player_fiat_balance(player_index)
    var bitcoin_balance = game_state.get_player_bitcoin_balance(player_index)
    player_balance.text = "%s EVA | %s BTC" % [fiat_balance, bitcoin_balance]
    player_color.color = game_state.get_player_accent_color(player_index)

func _on_turn_ended(next_player_index: int, next_tile_index: int):
    print("_on_turn_ended %s %s" % [next_player_index, next_tile_index])

func _on_dices_rolled(dice_1: int, dice_2: int, total: int) -> void:
    print("_on_dices_rolled %s + %s = %s" % [dice_1, dice_2, total])
    dice_1_label.visible = true
    dice_2_label.visible = true
    dice_1_label.text = str(dice_1)
    dice_2_label.text = str(dice_2)

    await get_tree().create_timer(1.0).timeout

    dice_1_label.visible = false
    dice_2_label.visible = false
    dice_result_shown.emit(dice_1, dice_2, total)

func _on_pawn_move_finished(_end_tile_index: int, _player_index: int) -> void:
    end_turn_button.visible = true
    var tile_info = game_state.get_tile_info(_end_tile_index)
    print("tile_info %s, %s. %s" % [tile_info.city, tile_info.property_price, tile_info.owner_index])
    card_ui.set_card(tile_info.city, tile_info.tile_type, tile_info.property_price, tile_info.owner_index, tile_info.miner_batches)

func _on_player_changed(new_index: int) -> void:
    print("_on_player_changed %s" % [new_index])
    # player_name.text = game_state.get_player_username(new_index)
    # var fiat_balance = game_state.get_player_fiat_balance(new_index)
    # var bitcoin_balance = game_state.get_player_bitcoin_balance(new_index)
    # player_balance.text = "%s EVA | %s BTC" % [fiat_balance, bitcoin_balance]
    # player_color.color = game_state.get_player_accent_color(new_index)

func _on_player_position_changed(tile_index: int, slot_index: int) -> void:
    print("_on_player_position_changed %s %s" % [tile_index, slot_index])

func _on_player_data_changed(player_index: int, player_data: PlayerData) -> void:
    print("_on_player_data_changed %s %s" % [player_index, player_data])

func _on_turn_state_changed(_player_index: int, turn_number: int, cycle_number: int) -> void:
    print("_on_turn_state_changed %s %s %s" % [_player_index, turn_number, cycle_number])

func _on_miner_batches_changed(tile_index: int, miner_batches: int, owner_index: int) -> void:
    print("_on_turn_state_changed %s %s %s" % [tile_index, miner_batches, owner_index])


# UI

func _on_end_turn_button_pressed() -> void:
    end_turn_button.visible = false
    card_ui.hide_card()
    end_turn_button_pressed.emit()

func _on_roll_dice_button_pressed() -> void:
    roll_dice_button.visible = false
    roll_dice_button_pressed.emit()
