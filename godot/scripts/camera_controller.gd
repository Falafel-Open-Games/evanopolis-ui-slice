extends Camera3D

@export var camera_positions: Array[Marker3D] = []
@export var pawns: Array[Node3D] = []
@export var move_duration: float = 1.5
@export var rotation_speed: float = 5.0
@export var focus_damping: float = 10.0

@onready var game_state: GameState = %GameState

var _target_node: Node3D = null
var _is_following: bool = false
var _current_tween: Tween = null
var _current_focus_point: Vector3 = Vector3.ZERO

func _ready() -> void:
	assert(game_state)
	assert(camera_positions.size() > 0)
	assert(pawns.size() > 0)
	assert(pawns[0])
	if not game_state.player_changed.is_connected(_on_player_changed):
		game_state.player_changed.connect(_on_player_changed)
	if not game_state.player_position_changed.is_connected(_on_player_position_changed):
		game_state.player_position_changed.connect(_on_player_position_changed)

	set_follow_target(pawns[0])

func _process(delta: float) -> void:
	if not _is_following:
		return
	assert(is_instance_valid(_target_node))
	var real_target_pos: Vector3 = _target_node.global_position
	_current_focus_point = _current_focus_point.lerp(real_target_pos, focus_damping * delta)

	if global_position.distance_squared_to(_current_focus_point) > 0.001:
		var target_xform: Transform3D = global_transform.looking_at(_current_focus_point, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_xform.basis, rotation_speed * delta)

func set_follow_target(new_target: Node3D) -> void:
	assert(new_target)
	_target_node = new_target
	_is_following = true
	_current_focus_point = new_target.global_position

func move_to_position(index: int) -> void:
	assert(index >= 0 and index < camera_positions.size())
	var target_marker: Marker3D = camera_positions[index]

	if _current_tween:
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_IN_OUT)
	_current_tween.set_trans(Tween.TRANS_CUBIC)
	_current_tween.tween_property(self, "global_position", target_marker.global_position, move_duration)

func _on_player_changed(new_index: int) -> void:
	assert(new_index >= 0 and new_index < pawns.size())
	set_follow_target(pawns[new_index])

func _on_player_position_changed(tile_index: int, slot_index: int) -> void:
	var target_camera_marker: int = get_side_for_tile(tile_index)
	move_to_position(target_camera_marker)

func get_side_for_tile(tile_index: int) -> int:
	var tiles_total: int = game_state.tiles.size()
	assert(tiles_total % 6 == 0)
	assert(tile_index >= 0 and tile_index < tiles_total)
	var tiles_per_side: int = tiles_total / 6
	var side_index: int = tile_index / tiles_per_side
	return side_index
