class_name CardDialog
extends CanvasLayer

@export var card : CardUi
@export var trade_button : Button
@export var miners_button : Button
@export var mortgage_button : Button
@export var close_button : Button
@export var miner_confirm_button : Button
@export var miners_buttons : Array[TextureButton]
@export var miners_counter : Label
@export var page_default : BoxContainer
@export var page_miner : BoxContainer
@export var page_mortgage : BoxContainer
@export var mortgage_confirm_button : Button
@export var mortgage_receive_value : Label
@export var mortgage_pay_value : Label

var _selected_miners : int
var game_controller: GameController
var game_state: GameState
var _miner_batch_price: float
var _current_miners_count: int
var _current_tile_index: int

func _ready() -> void:
    visible = false

    if not trade_button.pressed.is_connected(_on_trade_button_pressed):
        trade_button.pressed.connect(_on_trade_button_pressed)
    if not miners_button.pressed.is_connected(_on_miners_button_pressed):
        miners_button.pressed.connect(_on_miners_button_pressed)
    if not mortgage_button.pressed.is_connected(_on_mortgage_button_pressed):
        mortgage_button.pressed.connect(_on_mortgage_button_pressed)
    if not close_button.pressed.is_connected(_on_close_button_pressed):
        close_button.pressed.connect(_on_close_button_pressed)
    if not miner_confirm_button.pressed.is_connected(_on_miner_confirm_button):
        miner_confirm_button.pressed.connect(_on_miner_confirm_button)
    if not mortgage_confirm_button.pressed.is_connected(_on_mortgage_confirm_button):
        mortgage_confirm_button.pressed.connect(_on_mortgage_confirm_button)

    for i in range(miners_buttons.size()):
        var btn := miners_buttons[i]
        if btn:
            btn.pressed.connect(func(): _on_miners_buttons_pressed(i))

    page_default.visible = true
    page_miner.visible = false
    page_mortgage.visible = false

func set_dialog(_game_controller: GameController, _game_state: GameState):
    game_controller = _game_controller
    game_state = _game_state

func open_dialog(tile_index: int, title: String, type: Utils.TileType, toll_amount: float, miners: int, owner_name: String) -> void:
    visible = true
    page_default.visible = true
    page_miner.visible = false
    page_mortgage.visible = false
    _current_tile_index = tile_index
    _current_miners_count = miners
    var tile_info = game_state.get_tile_info(tile_index)
    card.set_card_owned(title, type, toll_amount, miners, owner_name, tile_info.is_mortgaged)
    var receive_value = tile_info.property_price * game_state.MORTGAGE_RECEIVE_RATE
    var pay_value = tile_info.property_price * game_state.MORTGAGE_PAY_RATE
    mortgage_receive_value.text = "%s EVA" % receive_value
    mortgage_pay_value.text = "%s EVA" % pay_value

    var is_mortgage_confirm_button_disabled = false

    if (
        (tile_info.is_mortgaged and not game_state.can_player_unmortgage(game_state.current_player_index, tile_info))
        or (not tile_info.is_mortgaged and not game_state.can_player_mortgage(game_state.current_player_index, tile_info))
    ):
        is_mortgage_confirm_button_disabled = true

    mortgage_confirm_button.disabled = is_mortgage_confirm_button_disabled
    mortgage_confirm_button.text = "PAY %s EVA" % pay_value if tile_info.is_mortgaged else "RECEIVE %s EVA" % receive_value

    _reset_miners_buttons()

    for i in _current_miners_count:
        miners_buttons[i].modulate = Color(0, 1, 0, 1)
        miners_buttons[i].disabled = true

    _on_miners_buttons_pressed(0) # Select 1 by default

func close_dialog():
    visible = false

func _on_trade_button_pressed() -> void:
    pass

func _on_miners_button_pressed() -> void:
    page_default.visible = false
    page_miner.visible = true
    page_mortgage.visible = false

func _on_mortgage_button_pressed() -> void:
    page_default.visible = false
    page_miner.visible = false
    page_mortgage.visible = true

func _on_close_button_pressed() -> void:
    close_dialog()

func _on_miners_buttons_pressed(button_index: int) -> void:
    _selected_miners = button_index + 1 - _current_miners_count
    miners_counter.text = "Adding %s of %s miners" % [_selected_miners, miners_buttons.size() - _current_miners_count]

    _reset_miners_buttons()

    # Bought miners
    for i in range(_current_miners_count):
        miners_buttons[i].modulate = Color(0, 0.7, 0, 1)
        miners_buttons[i].disabled = true

    # Available miners
    for i in range(_selected_miners):
        miners_buttons[i + _current_miners_count].modulate = Color(0, 0, 0, 1)

    _miner_batch_price = game_state.get_miner_batch_price_fiat() * _selected_miners
    miner_confirm_button.text = "%s EVA" % str(_miner_batch_price)

    var player_index = game_state.current_player_index
    var player_balance_fiat = game_state.get_player_fiat_balance(player_index)
    var is_affordable = _miner_batch_price < player_balance_fiat
    miner_confirm_button.disabled = not is_affordable

func _reset_miners_buttons():
    for btn in miners_buttons:
        btn.modulate = Color(0, 0, 0, 0.5)
        btn.disabled = false

func _on_miner_confirm_button():
    var player_index = game_state.current_player_index
    var order: Dictionary
    order[_current_tile_index] = _selected_miners
    game_state.set_pending_miner_order(player_index, order, false)
    game_state.apply_all_pending_miner_orders()
    close_dialog()

func _on_mortgage_confirm_button():
    var tile_info = game_state.get_tile_info(_current_tile_index)
    if tile_info.is_mortgaged:
        game_state.unmortgage_property(game_state.current_player_index, _current_tile_index)
    else:
        game_state.mortgage_property(game_state.current_player_index, _current_tile_index)
    close_dialog()
    pass
