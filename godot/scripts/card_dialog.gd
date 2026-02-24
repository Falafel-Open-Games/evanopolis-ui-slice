class_name CardDialog
extends CanvasLayer

@export var card : CardUi
@export var trade_button : Button
@export var miners_button : Button
@export var mortgage_button : Button
@export var close_button : Button
@export var miner_confirm_button : Button
@export var miners_buttons : Array[TextureButton]
@export var page_default : BoxContainer
@export var page_miner : BoxContainer
@export var miners_counter : Label

var _selected_miners : int
var game_controller: GameController
var game_state: GameState

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

    for i in range(miners_buttons.size()):
        var btn := miners_buttons[i]
        if btn:
            btn.pressed.connect(func(): _on_miners_buttons_pressed(i))

    page_default.visible = true
    page_miner.visible = false

func set_dialog(_game_controller: GameController, _game_state: GameState):
    game_controller = _game_controller
    game_state = _game_state

    _on_miners_buttons_pressed(0) # Select 1 by default

func open_dialog(title: String, type: Utils.TileType, toll_amount: float, miners: int, owner_name: String) -> void:
    visible = true
    page_default.visible = true
    page_miner.visible = false
    card.set_card_owned(title, type, toll_amount, miners, owner_name)

func close_dialog():
    visible = false

func _on_trade_button_pressed() -> void:
    pass

func _on_miners_button_pressed() -> void:
    page_default.visible = false
    page_miner.visible = true

func _on_mortgage_button_pressed() -> void:
    pass

func _on_close_button_pressed() -> void:
    close_dialog()

func _on_miners_buttons_pressed(button_index: int) -> void:
    _selected_miners = button_index + 1
    miners_counter.text = "Adding %s of %s miners" % [_selected_miners, miners_buttons.size()]

    for btn in miners_buttons:
        btn.modulate = Color(0, 0, 0, 0.5)

    for i in range(_selected_miners):
        miners_buttons[i].modulate = Color(0, 0, 0, 1)

    var miner_batch_price := game_state.get_miner_batch_price_fiat() * _selected_miners
    miner_confirm_button.text = "%s EVA" % str(miner_batch_price)
