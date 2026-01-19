class_name RightSidebar
extends FoldableContainer

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_player_state()
	property_container.visible = false

func set_current_player(index: int, player_display_name: String = "") -> void:
	player_index = clamp(index, 0, 5)
	if property_container:
		property_container.visible = false
	if player_display_name.is_empty():
		player_name = "Player %d" % [player_index + 1]
	else:
		player_name = player_display_name
	_apply_player_state()

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
