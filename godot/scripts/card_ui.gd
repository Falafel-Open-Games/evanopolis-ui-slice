class_name CardUi
extends Panel

signal card_selected(tile_index: int)

@export var title_label: Label
@export var card_type_label: Label
@export var price_label: Label
@export var owner_label: Label
@export var miners_label: Label
@export var card_image: TextureRect

var card_assuncion_with_mining_path = "res://textures/card-assuncion-with-mining.jpg"

# var _is_card_active: bool = false
var _initial_pos_y: float
var _initial_rot_deg: float
var _target_pos_y: float
var _tile_index: int

func _ready() -> void:
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_initial_position():
    _initial_pos_y = self.position.y
    _target_pos_y = _initial_pos_y - 320
    _initial_rot_deg = self.rotation_degrees

func set_card(title: String, type: Utils.TileType, price: float, owner_index: int, miners: int, owner_name: String, tile_index: int = -1):
    visible = true
    title_label.text = title.to_upper()
    card_type_label.text = Utils.TileType.keys()[type]
    price_label.text = str(price)
    owner_label.text = "AVAILABLE" if owner_index == -1 else "OWNED BY %s" % [owner_name]
    miners_label.text = "MINERS: %s" % [miners]
    miners_label.visible = miners > 0
    _tile_index = tile_index

    _set_card_texture(title, type, owner_index)

func hide_card():
    visible = false

# func _set_card_texture(title: String, type: String, miners: int):
func _set_card_texture(title: String, type: Utils.TileType, owner_index: int):
    if type != Utils.TileType.PROPERTY:
        card_image.visible = false
        return

    card_image.visible = true
    var path = _get_texture_path(title, owner_index)
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("Texture not found at: %s" % path)
        return
    card_image.texture = texture

func _get_texture_path(title: String, owner_index: int) -> String:
    # func _get_texture_path(title: String, miners: int) -> String:
    # var has_miners = "with" if miners > 0 else "without"
    var is_owned = "with" if owner_index != -1 else "without"
    var base_path = "res://textures/card-%s-%s-mining.jpg" % [to_dash_slug(title), is_owned]
    print("_get_texture_path %s, %s, %s" % [title, owner_index, base_path])
    return base_path

func to_dash_slug(text: String) -> String:
    var normalized := text.strip_edges().to_lower()
    return normalized.replace(" ", "-")

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton \
    and event.button_index == MOUSE_BUTTON_LEFT \
    and event.pressed:
        _on_clicked()

func _on_clicked() -> void:
    if _tile_index == -1:
        return

    card_selected.emit(_tile_index)

func _on_mouse_entered() -> void:
    _move_card(_target_pos_y, _initial_rot_deg - 5.0)

func _on_mouse_exited() -> void:
    _move_card(_initial_pos_y, _initial_rot_deg)

func _move_card(target_position_y: float, target_rotation_deg: float) -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "position:y", target_position_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.tween_property(self, "rotation_degrees", target_rotation_deg, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
