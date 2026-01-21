class_name RightSidebar
extends FoldableContainer

signal dice_rolled(die_1: int, die_2: int, total: int)
signal dice_requested

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
@onready var property_container: VBoxContainer = %PropertyContainer
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
@onready var movement_container: VBoxContainer = %MovementContainer
@onready var timer_container: HBoxContainer = %TimerContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(end_turn_button)
	_apply_player_state()
	_reset_roll_ui()
	_bind_timer_bar()

func _bind_timer_bar() -> void:
	if timer_bar == null:
		return
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
	if title_panel == null:
		return
	var panel_box: StyleBox = title_panel.duplicate()
	if panel_box is StyleBoxFlat:
		panel_box.bg_color = color
	add_theme_stylebox_override("title_panel", panel_box)

func _reset_roll_ui() -> void:
	if not dice_label_1:
		return
	dice_label_1.text = ""
	dice_label_2.text = ""
	_set_dice_panel_color(Color("#1a1a1a99"))
	movement_button.disabled = false
	_set_turn_start_visibility()
	if not movement_button.pressed.is_connected(_on_roll_pressed):
		movement_button.pressed.connect(_on_roll_pressed)

func _set_turn_start_visibility() -> void:
	if timer_container != null:
		timer_container.visible = true
	if movement_container != null:
		movement_container.visible = true
	if end_turn_button != null:
		end_turn_button.visible = false
	if movement_button != null:
		movement_button.visible = true
	if tile_type_label != null:
		tile_type_label.visible = false
	if property_container != null:
		property_container.visible = false

func set_turn_timer(duration_seconds: float, elapsed_seconds: float) -> void:
	if timer_bar == null:
		return
	var max_value: float = max(1.0, duration_seconds)
	var remaining: float = max(0.0, max_value - elapsed_seconds)
	timer_bar.max_value = max_value
	timer_bar.value = clamp(remaining, 0.0, max_value)
	timer_bar.show_percentage = false

func _on_timer_value_changed(value: float) -> void:
	if timer_label == null:
		return
	var remaining_seconds: int = int(value)
	timer_label.text = "%ds" % remaining_seconds

func _on_roll_pressed() -> void:
	dice_requested.emit()

func apply_dice_result(die_1: int, die_2: int) -> void:
	dice_label_1.text = str(die_1)
	dice_label_2.text = str(die_2)
	_set_dice_panel_color(Color("#ffffdc"))
	if movement_button != null:
		movement_button.visible = false
	if end_turn_button != null:
		end_turn_button.visible = true
	if tile_type_label != null:
		tile_type_label.visible = true
	dice_rolled.emit(die_1, die_2, die_1 + die_2)

func _set_dice_panel_color(color: Color) -> void:
	_set_panel_color(dice_panel_1, color)
	_set_panel_color(dice_panel_2, color)

func _set_panel_color(panel: Panel, color: Color) -> void:
	if panel == null:
		return
	var base_box: StyleBox = panel.get_theme_stylebox("panel")
	var panel_box: StyleBox = base_box.duplicate() if base_box != null else StyleBoxFlat.new()
	if panel_box is StyleBoxFlat:
		panel_box.bg_color = color
	panel.add_theme_stylebox_override("panel", panel_box)

func update_tile_info(tile_type: String, city: String, incident_kind: String) -> void:
	_update_tile_type_label(tile_type, city, incident_kind)
	if property_container == null:
		return
	if tile_type == "property" or tile_type == "special_property":
		property_container.visible = true
		_update_property_image(city)
	else:
		property_container.visible = false
		if property_image != null:
			property_image.texture = null

func _update_tile_type_label(tile_type: String, city: String, incident_kind: String) -> void:
	if tile_type_label == null:
		return
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
			if not city.is_empty():
				label_text += " (%s)" % [city]
		"property":
			label_text += "Property"
			if not city.is_empty():
				label_text += " (%s)" % [city]
		_:
			label_text += "Unknown"
	tile_type_label.text = label_text

func _update_property_image(city: String) -> void:
	if property_image == null:
		return
	var image_path: String = _get_city_image_path(city)
	if image_path.is_empty():
		property_image.texture = null
		return
	property_image.texture = load(image_path)

func _get_city_image_path(city: String) -> String:
	match city:
		"Caracas":
			return "res://textures/1-caracas-without-mining.png"
		"Assuncion":
			return "res://textures/2-assuncion-without-mining.png"
		"Ciudad del Este":
			return "res://textures/3-ciudad-del-este-without-mining.png"
		"Minsk":
			return "res://textures/4-minsk-without-mining.png"
		"Irkutsk":
			return "res://textures/5-irkutsk-without-mining.png"
		"Rockdale":
			return "res://textures/6-rockdale-without-mining.png"
		_:
			return ""
