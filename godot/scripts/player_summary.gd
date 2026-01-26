class_name PlayerSummary
extends FoldableContainer

@export_range(0, 5, 1) var player_index: int = 0
@onready var fiat_balance_label: Label = %FiatBalanceLabel
@onready var bitcoin_balance_label: Label = %BitcoinBalanceLabel
@onready var mining_power_label: Label = %MiningPowerLabel

func _ready() -> void:
	assert(fiat_balance_label)
	assert(bitcoin_balance_label)
	assert(mining_power_label)
	_apply_title_panel_style(Palette.get_player_dark(player_index))
	
	# set panel title based on player index
	self.title = "Player %d" % [player_index + 1]

func set_player_data(player_data: PlayerData) -> void:
	assert(player_data)
	set_fiat_balance(player_data.fiat_balance)
	set_bitcoin_balance(player_data.bitcoin_balance)
	set_mining_power(player_data.mining_power)

func set_fiat_balance(balance: float) -> void:
	assert(fiat_balance_label)
	fiat_balance_label.text = NumberFormat.format_fiat(balance)

func set_bitcoin_balance(balance: float) -> void:
	assert(bitcoin_balance_label)
	bitcoin_balance_label.text = "%.1f" % balance

func set_mining_power(power: int) -> void:
	assert(mining_power_label)
	mining_power_label.text = str(power)


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
