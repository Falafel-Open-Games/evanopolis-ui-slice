extends Control

@export var card_scene: PackedScene                     # assign Card.tscn in inspector
@export var max_cards: int = 12
@export var base_radius: float = 420.0                  # "distance" from pivot to card center
@export var max_fan_angle_deg: float = 40.0             # total spread (-angle..+angle)
@export var min_fan_angle_deg: float = 8.0              # spread when few cards
@export var vertical_offset: float = -40.0              # raise cards a bit from bottom

var game_controller: GameController
var game_state: GameState
var _cards: Array[Control] = []

signal card_selected(tile_index: int)

func _ready() -> void:
    anchor_left = 0.0
    anchor_right = 1.0
    anchor_top = 0.0
    anchor_bottom = 1.0
    offset_left = 0
    offset_top = 0
    offset_right = 0
    offset_bottom = 0
    self.position.y = 300

func set_inventory(_game_controller: GameController, _game_state: GameState):
    game_controller = _game_controller
    game_state = _game_state

    if not game_controller.turn_started.is_connected(_on_turn_started):
        game_controller.turn_started.connect(_on_turn_started)
    if not game_controller.property_purchased.is_connected(_on_property_purchased):
        game_controller.property_purchased.connect(_on_property_purchased)

func show_inventory():
    _animate_inventory(0)

func hide_inventory():
    _animate_inventory(300)

func _animate_inventory(target_position_y: int):
    var tween := create_tween()
    tween.set_parallel(false)
    tween.tween_property(self, "position:y", target_position_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func clear_cards() -> void:
    for c in _cards:
        if is_instance_valid(c):
            c.card_selected.disconnect(_on_card_selected)
            c.queue_free()
    _cards.clear()

func spawn_cards(count: int) -> void:
    clear_cards()
    count = clamp(count, 1, max_cards)

    for i in range(count):
        var card := card_scene.instantiate() as Panel
        add_child(card)
        card.pivot_offset = card.size * 0.5   # rotate around center
        _cards.append(card)
        card.card_selected.connect(_on_card_selected)

    _layout_cards()

func _layout_cards() -> void:
    if _cards.is_empty():
        return

    var n := _cards.size()

    var total_angle_deg = lerp(min_fan_angle_deg, max_fan_angle_deg,
        clamp((n - 1.0) / (max_cards - 1.0), 0.0, 1.0))
    if n == 1:
        total_angle_deg = 0.0

    var center_index := (n - 1) * 0.5

    var screen_size := get_viewport_rect().size
    # bottom center of the screen
    var base_pos := Vector2(screen_size.x * 0.5, screen_size.y)

    for i in range(n):
        var t := i - center_index
        var angle_deg := 0.0
        if n > 1:
            angle_deg = (t / center_index) * (total_angle_deg * 0.5)
        var angle_rad := deg_to_rad(angle_deg)

        var radius := base_radius
        # fan around bottom center: move up along -Y, spread on X
        var offset := Vector2(
            sin(angle_rad) * radius,
            -radius + vertical_offset   # vertical_offset is usually negative (pull up)
        )

        var card := _cards[i]
        card.rotation = angle_rad * 0.6
        card.position = base_pos + offset - card.pivot_offset
        card.set_initial_position()


func _reset_cards():
    var n := _cards.size()
    for i in range(n):
        _cards[i].hide_card()

func _on_turn_started(player_index: int, _tile_index: int):
    _populate_cards(player_index)

func _on_property_purchased(tile_index: int) -> void:
    var tile_info = game_state.get_tile_info(tile_index)
    _populate_cards(tile_info.owner_index)

func _on_card_selected(tile_index: int) -> void:
    print("card selected %s" % tile_index)
    card_selected.emit(tile_index)

func _populate_cards(player_index: int):
    clear_cards()
    var owned_tiles: Array[int] = game_state.get_owned_property_indices(player_index)
    var owned_tiles_size = owned_tiles.size()
    spawn_cards(owned_tiles_size)

    for i in range(owned_tiles_size):
        var tile_index = owned_tiles[i]
        var tile_info = game_state.get_tile_info(tile_index)
        var owner_name = game_state.get_player_username(tile_info.owner_index) if tile_info.owner_index != -1 else "NO OWNER"
        var is_property = tile_info.tile_type == Utils.TileType.PROPERTY or tile_info.tile_type == Utils.TileType.SPECIAL_PROPERTY
        var toll_amount = game_state.get_energy_toll(tile_info)

        if is_property:
            _cards[i].set_card_owned(tile_info.city, tile_info.tile_type, toll_amount, tile_info.miner_batches, owner_name, tile_index)
