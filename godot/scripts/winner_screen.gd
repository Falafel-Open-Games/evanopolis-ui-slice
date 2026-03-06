class_name WinnerScreen
extends CanvasLayer

@export var winner_name: Label
@export var bg: ColorRect
@export var panel: PanelContainer
@export var restart_button: Button

func _ready() -> void:
    if not restart_button.pressed.is_connected(_on_restart_button_pressed):
        restart_button.pressed.connect(_on_restart_button_pressed)

    hide_dialog_immediate()

func _on_restart_button_pressed() -> void:
    var next_scene = load("res://scenes/boot_menu.tscn")
    get_tree().change_scene_to_packed(next_scene)

func show_dialog(winner_player_name: String):
    visible = true
    winner_name.text = winner_player_name

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
