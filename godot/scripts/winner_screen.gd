class_name WinnerScreen
extends CanvasLayer

@export var winner_name: Label
@export var winner_currencies: Label
@export var bg: ColorRect
@export var panel: PanelContainer
@export var restart_button: Button
@export var list_of_players: VBoxContainer

var _game_state: GameState

func _ready() -> void:
    if not restart_button.pressed.is_connected(_on_restart_button_pressed):
        restart_button.pressed.connect(_on_restart_button_pressed)

    hide_dialog_immediate()

func set_panel(game_state: GameState):
    _game_state = game_state

func _on_restart_button_pressed() -> void:
    var next_scene = load("res://scenes/boot_menu.tscn")
    get_tree().change_scene_to_packed(next_scene)

func _populate_players():
    var players := _game_state.players
    players = Utils.sort_players_by_btc_desc(players)

    for player in players:
        if player.username == winner_name.text:
            continue

        var row := HBoxContainer.new()

        var name_label := Label.new()
        name_label.text = player.username
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

        var value_label := Label.new()
        value_label.text = "%s EVA | %s BTC" % [player.fiat_balance, player.bitcoin_balance]
        value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        row.add_child(name_label)
        row.add_child(value_label)

        list_of_players.add_child(row)

func show_dialog(player: PlayerData):
    visible = true
    winner_name.text = player.username
    winner_currencies.text = "%s EVA | %s BTC" % [player.fiat_balance, player.bitcoin_balance]
    _populate_players()

    bg.modulate.a = 0.0
    panel.scale = Vector2(0.8, 0.8)
    panel.modulate.a = 0.0

    var t := create_tween()
    t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # Background fade
    t.tween_property(bg, "modulate:a", 0.5, 0.2)

    # Panel pop‑in + fade
    t.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2)
    t.parallel().tween_property(panel, "modulate:a", 1.0, 0.2)

func hide_dialog():
    var t := create_tween()
    t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

    t.tween_property(bg, "modulate:a", 0.0, 0.15)
    t.parallel().tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
    t.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
    t.finished.connect(hide_dialog_immediate)

func hide_dialog_immediate():
    visible = false
