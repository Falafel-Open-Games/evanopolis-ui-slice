class_name CardUi
extends Panel

@export var title_label: Label
@export var card_type_label: Label
@export var price_label: Label
@export var owner_label: Label
@export var miners_label: Label
@export var card_image: TextureRect

var card_assuncion_with_mining_path = "res://textures/card-assuncion-with-mining.jpg"

func set_card(title: String, type: String, price: float, owner_index: int, miners: int):
    visible = true
    title_label.text = title.to_upper()
    card_type_label.text = type
    price_label.text = str(price)
    owner_label.text = "AVAILABLE" if owner_index == -1 else "OWNED BY %s" % [owner_index]
    miners_label.text = "MINERS: %s" % [miners]
    miners_label.visible = miners > 0

    _set_card_texture(title, type, miners)


func hide_card():
    visible = false

func _set_card_texture(title: String, type: String, miners: int):
    if type != "property":
        card_image.visible = false
        return

    card_image.visible = true
    var path = _get_texture_path(title, miners)
    var texture: Texture2D = load(path)
    if texture == null:
        push_error("Texture not found at: %s" % path)
        return
    card_image.texture = texture

func _get_texture_path(title: String, miners: int) -> String:
    var has_miners = "with" if miners > 0 else "without"
    var base_path = "res://textures/card-%s-%s-mining.jpg" % [title.to_lower(), has_miners]
    return base_path
