class_name CardDialog
extends CanvasLayer

@export var card : CardUi
@export var trade_button : Button
@export var miners_button : Button
@export var mortgage_button : Button
@export var close_button : Button

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

func open_dialog(title: String, type: Utils.TileType, toll_amount: float, miners: int, owner_name: String) -> void:
    visible = true
    card.set_card_owned(title, type, toll_amount, miners, owner_name)

func close_dialog():
    visible = false

func _on_trade_button_pressed() -> void:
    pass

func _on_miners_button_pressed() -> void:
    pass

func _on_mortgage_button_pressed() -> void:
    pass

func _on_close_button_pressed() -> void:
    close_dialog()
