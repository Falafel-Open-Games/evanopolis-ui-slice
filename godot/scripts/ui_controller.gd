class_name UiController
extends Node

signal end_turn_button_pressed
signal roll_dice_button_pressed
signal buy_property_button_pressed
signal pass_property_button_pressed
signal map_overview_button_pressed(is_active: bool)
signal dice_result_shown(dice_1: int, dice_2: int, total: int)

@export var game_controller: GameController
@export var game_state: GameState

@export var timer_label : Label
@export var player_name : Label
@export var player_balance : Label
@export var player_color : ColorRect
@export var dice_1_texture_rect : TextureRect
@export var dice_2_texture_rect : TextureRect
@export var end_turn_button : Button
@export var roll_dice_button : Button
@export var buy_property_button : Button
@export var pass_property_button : Button
@export var put_away_property_button : Button
@export var map_overview_button : Button
@export var inventory_button : Button
@export var card_ui : CardUi
@export var balance_variation_panel : PanelContainer
@export var balance_variation_label : Label
@export var balance_variation_spend_color : Color
@export var balance_variation_receive_color : Color
@export var turn_indicator_panel : PanelContainer
@export var turn_indicator_label : Label
@export var turn_indicator_player_color : ColorRect
@export var inventory : Control
@export var card_dialog : CardDialog

const TIMER_START_GAME := 2.0
const TIMER_APPLY_DICES_RESULT := 1.0
const TIMER_BALANCE_VARIATION := 3.0
const TIMER_TURN_INDICATOR := 3.0

var dice_texture_regions := [
    Rect2(0, 0, 200, 200),
    Rect2(240, 0, 200, 200),
    Rect2(480, 0, 200, 200),
    Rect2(0, 240, 200, 200),
    Rect2(240, 240, 200, 200),
    Rect2(480, 240, 200, 200),
]

var _is_map_overview_active: bool = false
var _is_inventory_active: bool = false

func _ready() -> void:
    # reset UI
    dice_1_texture_rect.visible = false
    dice_2_texture_rect.visible = false
    end_turn_button.visible = false
    roll_dice_button.visible = false
    buy_property_button.visible = false
    pass_property_button.visible = false
    put_away_property_button.visible = false
    balance_variation_panel.visible = false
    turn_indicator_panel.visible = false
    map_overview_button.visible = false
    card_ui.hide_card()
    card_dialog.close_dialog()
    inventory.set_inventory(game_controller, game_state)

    # bind states
    _bind_game_state()
    _bind_game_controller()
    _bind_ui_elements()

func _start_game() -> void:
    await get_tree().create_timer(TIMER_START_GAME).timeout

    roll_dice_button.visible = true
    map_overview_button.visible = true

func _bind_ui_elements() -> void:
    if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
        end_turn_button.pressed.connect(_on_end_turn_button_pressed)
    if not roll_dice_button.pressed.is_connected(_on_roll_dice_button_pressed):
        roll_dice_button.pressed.connect(_on_roll_dice_button_pressed)
    if not buy_property_button.pressed.is_connected(_on_buy_property_button_pressed):
        buy_property_button.pressed.connect(_on_buy_property_button_pressed)
    if not pass_property_button.pressed.is_connected(_on_pass_property_button_pressed):
        pass_property_button.pressed.connect(_on_pass_property_button_pressed)
    if not put_away_property_button.pressed.is_connected(_on_put_away_property_button_pressed):
        put_away_property_button.pressed.connect(_on_put_away_property_button_pressed)
    if not map_overview_button.pressed.is_connected(_on_map_overview_button_pressed):
        map_overview_button.pressed.connect(_on_map_overview_button_pressed)
    if not inventory_button.pressed.is_connected(_on_inventory_button_pressed):
        inventory_button.pressed.connect(_on_inventory_button_pressed)
    if not inventory.card_selected.is_connected(_on_card_selected):
        inventory.card_selected.connect(_on_card_selected)

func _bind_game_controller() -> void:
    if not game_controller.timer_elapsed.is_connected(_on_timer_elapsed):
        game_controller.timer_elapsed.connect(_on_timer_elapsed)
    if not game_controller.turn_started.is_connected(_on_turn_started):
        game_controller.turn_started.connect(_on_turn_started)
    if not game_controller.turn_ended.is_connected(_on_turn_ended):
        game_controller.turn_ended.connect(_on_turn_ended)
    if not game_controller.dices_rolled.is_connected(_on_dices_rolled):
        game_controller.dices_rolled.connect(_on_dices_rolled)
    if not game_controller.pawn_move_started.is_connected(_on_pawn_move_started):
        game_controller.pawn_move_started.connect(_on_pawn_move_started)
    if not game_controller.pawn_move_finished.is_connected(_on_pawn_move_finished):
        game_controller.pawn_move_finished.connect(_on_pawn_move_finished)
    if not game_controller.property_purchased.is_connected(_on_property_purchased):
        game_controller.property_purchased.connect(_on_property_purchased)

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
    map_overview_button.visible = true
    player_name.text = game_state.get_player_username(player_index)
    var fiat_balance = game_state.get_player_fiat_balance(player_index)
    var bitcoin_balance = game_state.get_player_bitcoin_balance(player_index)
    player_balance.text = "%s EVA | %s BTC" % [fiat_balance, bitcoin_balance]
    player_color.color = game_state.get_player_accent_color(player_index)

    turn_indicator_label.text = "%s IS UP" % game_state.get_player_username(player_index).to_upper()
    turn_indicator_player_color.color = game_state.get_player_accent_color(player_index)
    turn_indicator_panel.visible = true
    _show_turn_indicator_panel()

    await get_tree().create_timer(TIMER_TURN_INDICATOR).timeout

    _hide_turn_indicator_panel()

func _show_turn_indicator_panel():
    var tween := create_tween()
    tween.set_parallel(false)
    var viewport_size := get_viewport().get_visible_rect().size
    turn_indicator_panel.position.x = viewport_size.x
    turn_indicator_panel.position.y = 100
    tween.tween_property(turn_indicator_panel, "position:x", viewport_size.x - turn_indicator_panel.size.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _hide_turn_indicator_panel():
    var tween := create_tween()
    tween.set_parallel(false)
    var viewport_size := get_viewport().get_visible_rect().size
    turn_indicator_panel.position.x = viewport_size.x - turn_indicator_panel.size.x
    turn_indicator_panel.position.y = 100
    tween.tween_property(turn_indicator_panel, "position:x", viewport_size.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_turn_ended(next_player_index: int, next_tile_index: int):
    print("_on_turn_ended %s %s" % [next_player_index, next_tile_index])

func _on_dices_rolled(dice_1: int, dice_2: int, total: int) -> void:
    print("_on_dices_rolled %s + %s = %s" % [dice_1, dice_2, total])
    dice_1_texture_rect.visible = true
    dice_2_texture_rect.visible = true

    var atlas_1 = dice_1_texture_rect.texture as AtlasTexture
    atlas_1.region = dice_texture_regions[dice_1 - 1]

    var atlas_2 = dice_2_texture_rect.texture as AtlasTexture
    atlas_2.region = dice_texture_regions[dice_2 - 1]

    await get_tree().create_timer(TIMER_APPLY_DICES_RESULT).timeout

    dice_1_texture_rect.visible = false
    dice_2_texture_rect.visible = false
    dice_result_shown.emit(dice_1, dice_2, total)

func _on_pawn_move_started(_start_tile_index: int, _end_tile_index: int, _player_index: int) -> void:
    map_overview_button.visible = false

func _on_pawn_move_finished(_end_tile_index: int, _player_index: int) -> void:
    var tile_info = game_state.get_tile_info(_end_tile_index)
    var owner_name = game_state.get_player_username(tile_info.owner_index) if tile_info.owner_index != -1 else "NO OWNER"
    var is_property = tile_info.tile_type == Utils.TileType.PROPERTY or tile_info.tile_type == Utils.TileType.SPECIAL_PROPERTY

    map_overview_button.visible = true

    if is_property:
        card_ui.set_card(tile_info.city, tile_info.tile_type, tile_info.property_price, tile_info.owner_index, tile_info.miner_batches, owner_name)
        var buy_visible: bool = tile_info.owner_index == -1
        buy_property_button.visible = buy_visible
        pass_property_button.visible = buy_visible
    else:
        end_turn_button.visible = true

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
    player_balance.text = "%s EVA | %s BTC" % [player_data.fiat_balance, player_data.bitcoin_balance]

func _on_turn_state_changed(_player_index: int, turn_number: int, cycle_number: int) -> void:
    print("_on_turn_state_changed %s %s %s" % [_player_index, turn_number, cycle_number])

func _on_miner_batches_changed(tile_index: int, miner_batches: int, owner_index: int) -> void:
    print("_on_turn_state_changed %s %s %s" % [tile_index, miner_batches, owner_index])

func _on_property_purchased(tile_index: int) -> void:
    var tile_info = game_state.get_tile_info(tile_index)
    var owner_name = game_state.get_player_username(tile_info.owner_index) if tile_info.owner_index != -1 else "NO OWNER"
    card_ui.set_card(tile_info.city, tile_info.tile_type, tile_info.property_price, tile_info.owner_index, tile_info.miner_batches, owner_name)
    put_away_property_button.visible = true
    _spend_value_balance_variation(int(tile_info.property_price))

func _spend_value_balance_variation(spent_value: int):
    balance_variation_label.text = "- %s EVA" % str(spent_value)
    var stylebox := balance_variation_panel.get_theme_stylebox("panel").duplicate()
    stylebox.bg_color = balance_variation_spend_color
    balance_variation_panel.add_theme_stylebox_override("panel", stylebox)
    balance_variation_panel.visible = true

    await get_tree().create_timer(TIMER_BALANCE_VARIATION).timeout

    balance_variation_panel.visible = false

func _receive_value_balance_variation(add_value: int):
    balance_variation_label.text = "+ %s EVA" % str(add_value)
    var stylebox := balance_variation_panel.get_theme_stylebox("panel").duplicate()
    stylebox.bg_color = balance_variation_receive_color
    balance_variation_panel.add_theme_stylebox_override("panel", stylebox)
    balance_variation_panel.visible = true

    await get_tree().create_timer(TIMER_BALANCE_VARIATION).timeout

    balance_variation_panel.visible = false

# UI

func _on_end_turn_button_pressed() -> void:
    card_ui.hide_card()
    end_turn_button.visible = false
    balance_variation_panel.visible = false
    end_turn_button_pressed.emit()

func _on_roll_dice_button_pressed() -> void:
    roll_dice_button.visible = false
    roll_dice_button_pressed.emit()

func _on_buy_property_button_pressed() -> void:
    buy_property_button.visible = false
    pass_property_button.visible = false
    card_ui.hide_card()
    buy_property_button_pressed.emit()

func _on_pass_property_button_pressed() -> void:
    buy_property_button.visible = false
    pass_property_button.visible = false
    card_ui.hide_card()
    pass_property_button_pressed.emit()
    end_turn_button.visible = true

func _on_put_away_property_button_pressed() -> void:
    put_away_property_button.visible = false
    balance_variation_panel.visible = false
    card_ui.hide_card()
    end_turn_button.visible = true

func _on_map_overview_button_pressed() -> void:
    _is_map_overview_active = not _is_map_overview_active
    map_overview_button_pressed.emit(_is_map_overview_active)

func _on_inventory_button_pressed() -> void:
    _is_inventory_active = not _is_inventory_active

    if _is_inventory_active:
        inventory.show_inventory()
    else:
        inventory.hide_inventory()

func _on_card_selected(tile_index: int) -> void:
    var tile_info = game_state.get_tile_info(tile_index)
    var owner_name = game_state.get_player_username(tile_info.owner_index) if tile_info.owner_index != -1 else "NO OWNER"
    var is_property = tile_info.tile_type == Utils.TileType.PROPERTY or tile_info.tile_type == Utils.TileType.SPECIAL_PROPERTY

    if is_property:
        card_dialog.open_dialog(tile_info.city, tile_info.tile_type, tile_info.property_price, tile_info.owner_index, tile_info.miner_batches, owner_name)
