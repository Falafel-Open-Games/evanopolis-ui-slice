class_name PlayerSummary
extends FoldableContainer

@export_range(0, 5, 1) var player_index: int = 0
@onready var fiat_balance_label: Label = %FiatBalanceLabel
@onready var bitcoin_balance_label: Label = %BitcoinBalanceLabel
@onready var mining_power_label: Label = %MiningPowerLabel
@onready var view_properties_button: Button = %ViewPropertiesButton
@onready var properties_panel: PanelContainer = %PropertiesPanel
@onready var properties_list: VBoxContainer = %PropertiesList
@onready var order_total_label: Label = %OrderTotalLabel
@onready var confirm_fiat_button: Button = %ConfirmFiatButton
@onready var confirm_btc_button: Button = %ConfirmBtcButton
@onready var close_properties_button: Button = %ClosePropertiesButton
@onready var order_locked_label: Label = %OrderLockedLabel

var _game_state: GameState
var _order_counts: Dictionary = {}
var _can_edit_order: bool = true

func _ready() -> void:
	assert(fiat_balance_label)
	assert(bitcoin_balance_label)
	assert(mining_power_label)
	assert(view_properties_button)
	assert(properties_panel)
	assert(properties_list)
	assert(order_total_label)
	assert(confirm_fiat_button)
	assert(confirm_btc_button)
	assert(close_properties_button)
	assert(order_locked_label)
	_apply_title_panel_style(Palette.get_player_dark(player_index))
	
	# set panel title based on player index
	self.title = "Player %d" % [player_index + 1]
	if not view_properties_button.pressed.is_connected(_on_view_properties_pressed):
		view_properties_button.pressed.connect(_on_view_properties_pressed)
	if not confirm_fiat_button.pressed.is_connected(_on_confirm_fiat_pressed):
		confirm_fiat_button.pressed.connect(_on_confirm_fiat_pressed)
	if not confirm_btc_button.pressed.is_connected(_on_confirm_btc_pressed):
		confirm_btc_button.pressed.connect(_on_confirm_btc_pressed)
	if not close_properties_button.pressed.is_connected(_on_close_properties_pressed):
		close_properties_button.pressed.connect(_on_close_properties_pressed)

func set_player_data(player_data: PlayerData) -> void:
	assert(player_data)
	set_fiat_balance(player_data.fiat_balance)
	set_bitcoin_balance(player_data.bitcoin_balance)
	set_mining_power(player_data.mining_power)

func set_game_state(game_state: GameState) -> void:
	assert(game_state)
	_game_state = game_state
	if not _game_state.miner_order_committed.is_connected(_on_miner_order_committed):
		_game_state.miner_order_committed.connect(_on_miner_order_committed)
	if not _game_state.miner_order_locked.is_connected(_on_miner_order_locked):
		_game_state.miner_order_locked.connect(_on_miner_order_locked)

func set_fiat_balance(balance: float) -> void:
	assert(fiat_balance_label)
	fiat_balance_label.text = NumberFormat.format_fiat(balance)

func set_bitcoin_balance(balance: float) -> void:
	assert(bitcoin_balance_label)
	bitcoin_balance_label.text = "%.8f" % balance

func set_mining_power(power: int) -> void:
	assert(mining_power_label)
	mining_power_label.text = str(power)

func _on_view_properties_pressed() -> void:
	properties_panel.visible = not properties_panel.visible
	if properties_panel.visible:
		_refresh_properties_view()

func _on_close_properties_pressed() -> void:
	properties_panel.visible = false

func _on_confirm_fiat_pressed() -> void:
	_confirm_order(false)

func _on_confirm_btc_pressed() -> void:
	_confirm_order(true)

func _confirm_order(use_bitcoin: bool) -> void:
	assert(_game_state)
	if not _can_edit_order:
		return
	var order: Dictionary = {}
	for tile_index in _order_counts.keys():
		var count: int = int(_order_counts[tile_index])
		if count > 0:
			order[tile_index] = count
	var did_set: bool = _game_state.set_pending_miner_order(player_index, order, use_bitcoin)
	if did_set:
		_refresh_properties_view()

func _refresh_properties_view() -> void:
	assert(_game_state)
	_clear_property_list()
	_order_counts = {}
	var owned_tiles: Array[int] = _game_state.get_owned_property_indices(player_index)
	_can_edit_order = _game_state.can_place_miner_order(player_index)
	order_locked_label.visible = not _can_edit_order
	if owned_tiles.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No properties yet"
		properties_list.add_child(empty_label)
		_update_order_total()
		_update_confirm_buttons()
		return
	var pending_order: Dictionary = _game_state.get_pending_miner_order(player_index)
	for tile_index in owned_tiles:
		_add_property_row(tile_index, pending_order)
	_update_order_total()
	_update_confirm_buttons()

func _add_property_row(tile_index: int, pending_order: Dictionary) -> void:
	var tile: TileInfo = _game_state.get_tile_info(tile_index)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(48, 48)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var image_path: String = _get_city_image_path(tile.city)
	if not image_path.is_empty():
		texture_rect.texture = load(image_path)
	row.add_child(texture_rect)

	var info_label: Label = Label.new()
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pending_count: int = int(pending_order.get(tile_index, 0))
	if _can_edit_order:
		info_label.text = "%s\nMiners: %d" % [tile.city, tile.miner_batches]
	else:
		info_label.text = "%s\nMiners: %d (+%d pending)" % [tile.city, tile.miner_batches, pending_count]
	row.add_child(info_label)

	var spinner: SpinBox = SpinBox.new()
	spinner.step = 1.0
	spinner.min_value = 0.0
	var max_additional: int = GameState.MAX_MINER_BATCHES_PER_PROPERTY - tile.miner_batches
	if max_additional < 0:
		max_additional = 0
	spinner.max_value = float(max_additional)
	spinner.value = float(pending_count if not _can_edit_order else 0)
	spinner.editable = _can_edit_order
	spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _can_edit_order:
		spinner.value_changed.connect(_on_spinner_changed.bind(tile_index))
	_order_counts[tile_index] = int(spinner.value)
	row.add_child(spinner)

	properties_list.add_child(row)

func _on_spinner_changed(value: float, tile_index: int) -> void:
	_order_counts[tile_index] = int(value)
	_update_order_total()
	_update_confirm_buttons()

func _update_order_total() -> void:
	assert(_game_state)
	var total_batches: int = 0
	for count in _order_counts.values():
		total_batches += int(count)
	var total_fiat: float = float(total_batches) * _game_state.get_miner_batch_price_fiat()
	var total_btc: float = float(total_batches) * _game_state.get_miner_batch_price_btc()
	order_total_label.text = "Order Total: %s fiat | %s BTC" % [
		NumberFormat.format_fiat(total_fiat),
		NumberFormat.format_btc(total_btc),
	]

func _update_confirm_buttons() -> void:
	var total_batches: int = 0
	for count in _order_counts.values():
		total_batches += int(count)
	var disabled: bool = total_batches == 0 or not _can_edit_order
	confirm_fiat_button.disabled = disabled
	confirm_btc_button.disabled = disabled

func _clear_property_list() -> void:
	for child in properties_list.get_children():
		properties_list.remove_child(child)
		child.queue_free()

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

func _on_miner_order_committed(committed_player_index: int) -> void:
	if committed_player_index != player_index:
		return
	if properties_panel.visible:
		_refresh_properties_view()

func _on_miner_order_locked(locked_player_index: int, _locked: bool) -> void:
	if locked_player_index != player_index:
		return
	if properties_panel.visible:
		_refresh_properties_view()


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
