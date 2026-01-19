class_name RightSidebar
extends FoldableContainer

signal dice_rolled(die_1: int, die_2: int, total: int)

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
@onready var movement_button: Button = %MovementButton
@onready var dice_1_label: Label = %Dice1Label
@onready var dice_2_label: Label = %Dice2Label
@onready var tile_type_label: Label = %TileTypeLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_player_state()
	property_container.visible = false
	_reset_roll_ui()

func set_current_player(index: int, player_display_name: String = "") -> void:
	player_index = clamp(index, 0, 5)
	if property_container:
		property_container.visible = false
	if player_display_name.is_empty():
		player_name = "Player %d" % [player_index + 1]
	else:
		player_name = player_display_name
	_apply_player_state()
	_reset_roll_ui()
	_update_tile_type_label("start", "", "")

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
	if not dice_1_label:
		return
	dice_1_label.text = ""
	dice_2_label.text = ""
	movement_button.disabled = false
	if not movement_button.pressed.is_connected(_on_roll_pressed):
		movement_button.pressed.connect(_on_roll_pressed)

func _on_roll_pressed() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var die_1: int = rng.randi_range(1, 6)
	var die_2: int = rng.randi_range(1, 6)
	var total: int = die_1 + die_2
	dice_1_label.text = str(die_1)
	dice_2_label.text = str(die_2)
	movement_button.disabled = true
	dice_rolled.emit(die_1, die_2, total)

func update_tile_info(tile_type: String, city: String, incident_kind: String) -> void:
	_update_tile_type_label(tile_type, city, incident_kind)
	if property_container == null:
		return
	if tile_type == "property" or tile_type == "special_property":
		property_container.visible = true
	else:
		property_container.visible = false

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
