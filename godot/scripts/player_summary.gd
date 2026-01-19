extends FoldableContainer

@export_range(0, 5, 1) var player_index = 0

func _ready() -> void:
	_apply_title_panel_style(Palette.get_player_dark(player_index))
	
	# set panel title based on player index
	self.title = "Player %d" % [player_index + 1]

func _apply_title_panel_style(dark_color: Color) -> void:
	self.add_theme_color_override("font_color", Color.WHITE)
	self.add_theme_color_override("font_hover_color", Color.WHITE)
	self.add_theme_color_override("collapsed_font_color", Color.WHITE)
	self.add_theme_color_override("collapsed_font_hover_color", Color.WHITE)

	_set_title_panel_color("title_panel", dark_color)
	_set_title_panel_color("title_hover_panel", dark_color)
	_set_title_panel_color("title_collapsed_panel", dark_color)
	_set_title_panel_color("title_collapsed_hover_panel", dark_color)

func _set_title_panel_color(style_name: String, color: Color) -> void:
	var base_box: StyleBox = get_theme_stylebox(style_name)
	var panel_box: StyleBox = base_box.duplicate() if base_box != null else StyleBoxFlat.new()
	if panel_box is StyleBoxFlat:
		panel_box.bg_color = color
	add_theme_stylebox_override(style_name, panel_box)
