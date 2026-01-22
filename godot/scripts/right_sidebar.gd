class_name RightSidebar
extends FoldableContainer

signal dice_rolled(die_1: int, die_2: int, total: int)
signal dice_requested
signal buy_pressed

@export_range(0, 5, 1) var player_index: int = 0:
	set(value):
		player_index = value
		if is_inside_tree():
			_apply_player_state()

@export var player_name: String = "Player 1":
	set(value):
		player_name = value
		if is_inside_tree():
			_apply_player_state()

@onready var end_turn_button: Button = %EndTurnButton
@onready var property_container: BoxContainer = %PropertyContainer
@onready var property_image: TextureRect = %Image
@onready var movement_button: Button = %MovementButton
@onready var dice_panel_1: Panel = %DicePanel1
@onready var dice_panel_2: Panel = %DicePanel2
@onready var dice_label_1: Label = %DiceLabel1
@onready var dice_label_2: Label = %DiceLabel2
@onready var tile_type_label: Label = %TileTypeLabel
@onready var image: TextureRect = %Image
@onready var timer_bar: ProgressBar = %TimerBar
@onready var timer_label: Label = %TimerLabel
@onready var movement_container: BoxContainer = %MovementContainer
@onready var timer_container: BoxContainer = %TimerContainer
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var owner_label: Label = %OwnerLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(end_turn_button)
	assert(property_container)
	assert(property_image)
	assert(movement_button)
	assert(dice_panel_1)
	assert(dice_panel_2)
	assert(dice_label_1)
	assert(dice_label_2)
	assert(tile_type_label)
	assert(timer_bar)
	assert(timer_label)
	assert(movement_container)
	assert(timer_container)
	assert(price_label)
	assert(owner_label)
	assert(buy_button)
	_apply_player_state()
	_reset_roll_ui()
	_bind_timer_bar()
	if not buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.connect(_on_buy_pressed)

func _bind_timer_bar() -> void:
	assert(timer_bar)
	if not timer_bar.value_changed.is_connected(_on_timer_value_changed):
		timer_bar.value_changed.connect(_on_timer_value_changed)
	_on_timer_value_changed(timer_bar.value)

func set_current_player(index: int, player_display_name: String = "") -> void:
	player_index = clamp(index, 0, 5)
	if player_display_name.is_empty():
		player_name = "Player %d" % [player_index + 1]
	else:
		player_name = player_display_name
	_apply_player_state()
	_reset_roll_ui()

func _apply_player_state() -> void:
	self.title = "Current Turn: %s" % [player_name]
	self.add_theme_color_override("font_color", Color.WHITE)
	self.add_theme_color_override("collapsed_font_color", Color.WHITE)
	_apply_title_panel_color(Palette.get_player_dark(player_index))

func _apply_title_panel_color(color: Color) -> void:
	var title_panel: StyleBox = get_theme_stylebox("title_panel")
	assert(title_panel)
	var panel_box: StyleBox = title_panel.duplicate()
	if panel_box is StyleBoxFlat:
		panel_box.bg_color = color
	add_theme_stylebox_override("title_panel", panel_box)

func _reset_roll_ui() -> void:
	assert(dice_label_1)
	assert(dice_label_2)
	assert(movement_button)
	dice_label_1.text = ""
	dice_label_2.text = ""
	_set_dice_panel_color(Color("#1a1a1a99"))
	movement_button.disabled = false
	_set_turn_start_visibility()
	if not movement_button.pressed.is_connected(_on_roll_pressed):
		movement_button.pressed.connect(_on_roll_pressed)

func _set_turn_start_visibility() -> void:
	assert(timer_container)
	assert(movement_container)
	assert(end_turn_button)
	assert(movement_button)
	assert(tile_type_label)
	assert(property_container)
	assert(price_label)
	assert(owner_label)
	assert(buy_button)
	timer_container.visible = true
	movement_container.visible = true
	end_turn_button.visible = false
	movement_button.visible = true
	tile_type_label.visible = false
	property_container.visible = false
	price_label.visible = false
	owner_label.visible = false
	buy_button.visible = false

func set_turn_timer(duration_seconds: float, elapsed_seconds: float) -> void:
	assert(timer_bar)
	var max_value: float = max(1.0, duration_seconds)
	var remaining: float = max(0.0, max_value - elapsed_seconds)
	timer_bar.max_value = max_value
	timer_bar.value = clamp(remaining, 0.0, max_value)
	timer_bar.show_percentage = false

func _on_timer_value_changed(value: float) -> void:
	assert(timer_label)
	var remaining_seconds: int = int(value)
	timer_label.text = "%ds" % remaining_seconds

func _on_roll_pressed() -> void:
	dice_requested.emit()

func apply_dice_result(die_1: int, die_2: int) -> void:
	dice_label_1.text = str(die_1)
	dice_label_2.text = str(die_2)
	_set_dice_panel_color(Color("#ffffdc"))
	assert(movement_button)
	assert(end_turn_button)
	assert(tile_type_label)
	movement_button.visible = false
	end_turn_button.visible = true
	tile_type_label.visible = true
	dice_rolled.emit(die_1, die_2, die_1 + die_2)

func _set_dice_panel_color(color: Color) -> void:
	_set_panel_color(dice_panel_1, color)
	_set_panel_color(dice_panel_2, color)

func _set_panel_color(panel: Panel, color: Color) -> void:
	assert(panel)
	var base_box: StyleBox = panel.get_theme_stylebox("panel")
	var panel_box: StyleBox = base_box.duplicate() if base_box != null else StyleBoxFlat.new()
	if panel_box is StyleBoxFlat:
		panel_box.bg_color = color
	panel.add_theme_stylebox_override("panel", panel_box)

func update_tile_info(
	tile_type: String,
	city: String,
	incident_kind: String,
	property_price: float,
	special_name: String,
	special_price: float,
	is_owned: bool,
	owner_name: String,
	buy_visible: bool,
	buy_enabled: bool
) -> void:
	_update_tile_type_label(tile_type, city, incident_kind, special_name)
	assert(property_container)
	if tile_type == "property" or tile_type == "special_property":
		property_container.visible = true
		_update_property_image(city, is_owned)
		_update_price_label(tile_type, property_price, special_price)
		_update_owner_label(is_owned, owner_name)
		_update_buy_button(buy_visible, buy_enabled)
	else:
		property_container.visible = false
		assert(property_image)
		property_image.texture = null
		assert(price_label)
		assert(buy_button)
		assert(owner_label)
		price_label.visible = false
		owner_label.visible = false
		buy_button.visible = false

func _update_tile_type_label(
	tile_type: String,
	city: String,
	incident_kind: String,
	special_name: String
) -> void:
	assert(tile_type_label)
	var label_text: String = "You landed on a: "
	match tile_type:
		"start":
			label_text += "Start"
		"inspection":
			label_text += "Inspection"
		"incident":
			label_text += "Incident"
			if not incident_kind.is_empty():
				label_text += " (%s)" % [incident_kind.capitalize()]
		"special_property":
			label_text += "Special Property"
			if not special_name.is_empty():
				label_text += " (%s)" % [special_name]
		"property":
			label_text += "Property"
			if not city.is_empty():
				label_text += " (%s)" % [city]
		_:
			label_text += "Unknown"
	tile_type_label.text = label_text

func _update_price_label(
	tile_type: String,
	property_price: float,
	special_price: float
) -> void:
	assert(price_label)
	if tile_type == "property":
		price_label.text = "Price: %.1f" % property_price
		price_label.visible = true
	elif tile_type == "special_property":
		price_label.text = "Price: %.1f" % special_price
		price_label.visible = true
	else:
		price_label.visible = false

func _update_owner_label(is_owned: bool, owner_name: String) -> void:
	assert(owner_label)
	if not is_owned or owner_name.is_empty():
		owner_label.visible = false
		return
	owner_label.text = "Owner: %s" % owner_name
	owner_label.visible = true

func _update_buy_button(buy_visible: bool, buy_enabled: bool) -> void:
	assert(buy_button)
	buy_button.visible = buy_visible
	buy_button.disabled = not buy_enabled

func _on_buy_pressed() -> void:
	buy_pressed.emit()

func _update_property_image(city: String, owned: bool) -> void:
	assert(property_image)
	var image_path: String = _get_city_image_path(city, owned)
	if image_path.is_empty():
		property_image.texture = null
		return
	property_image.texture = load(image_path)

func _get_city_image_path(city: String, owned: bool) -> String:
	var suffix: String = "with-mining" if owned else "without-mining"
	match city:
		"Caracas":
			return "res://textures/1-caracas-%s.png" % suffix
		"Assuncion":
			return "res://textures/2-assuncion-%s.png" % suffix
		"Ciudad del Este":
			return "res://textures/3-ciudad-del-este-%s.png" % suffix
		"Minsk":
			return "res://textures/4-minsk-%s.png" % suffix
		"Irkutsk":
			return "res://textures/5-irkutsk-%s.png" % suffix
		"Rockdale":
			return "res://textures/6-rockdale-%s.png" % suffix
		_:
			return ""
