class_name CameraTileRig
extends Camera3D

enum FollowYMode {
	TABLE = 0,
	TARGET_BASE = 1,
}

@export var board_layout: Node
@export var pose_rig: Node3D
@export var pose_tile_ref: Node3D
@export var pose_camera_zoom_out: Camera3D
@export var pose_camera_zoom_in: Camera3D
@export var game_controller: GameController
@export var prezoom_duration: float = 1.5
@export var prezoom_start_ratio: float = 0.5
@export var look_at_on_snap: bool = true
@export var follow_rotation_speed: float = 6.0
@export var pose_flip_yaw_180: bool = true

var _base_basis: Basis = Basis.IDENTITY
var _base_origin: Vector3 = Vector3.ZERO
var _zoom_blend: float = 0.0
var _zoom_out_fov: float = 55.0
var _zoom_in_fov: float = 15.0
var _follow_target: Node3D = null
var _follow_enabled: bool = false
var _fov_tween: Tween = null
var _zoom_out_relative: Transform3D = Transform3D.IDENTITY
var _zoom_in_relative: Transform3D = Transform3D.IDENTITY
var _dice_camera_timer: SceneTreeTimer = null
var _dice_camera_token: int = 0
var _follow_base_y: float = 0.0
@export var follow_y_mode: int = FollowYMode.TABLE

func _ready() -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	assert(game_controller)
	assert(pose_rig)
	assert(pose_tile_ref)
	assert(pose_camera_zoom_out)
	assert(pose_camera_zoom_in)
	_set_base_transform(global_transform)
	set_zoom(false)
	_capture_pose_relatives()
	pose_rig.visible = false
	set_process(true)
	_bind_game_controller()

func snap_to_tile(tile_index: int, look_at_player_index: int = -1) -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	var tiles: Array[Node3D] = board_layout.get_board_tiles()
	assert(tile_index >= 0 and tile_index < tiles.size())
	var tile: Node3D = tiles[tile_index]
	_set_base_transform(tile.global_transform)
	if look_at_on_snap:
		if look_at_player_index >= 0:
			_look_at_tile_slot(tile_index, look_at_player_index)
		else:
			_look_at_current_player()

func set_zoom(is_zoom_in: bool) -> void:
	var target_fov: float = _zoom_in_fov if is_zoom_in else _zoom_out_fov
	var target_blend: float = 1.0 if is_zoom_in else 0.0
	fov = target_fov
	_set_zoom_blend(target_blend)

func tween_fov(target_fov: float, duration: float) -> void:
	if _fov_tween:
		_fov_tween.kill()
	_fov_tween = create_tween()
	_fov_tween.set_ease(Tween.EASE_IN_OUT)
	_fov_tween.set_trans(Tween.TRANS_CUBIC)
	_fov_tween.tween_property(self, "fov", target_fov, duration)

func start_follow(target: Node3D) -> void:
	assert(target)
	_follow_target = target
	_follow_enabled = true
	_follow_base_y = target.global_position.y

func stop_follow() -> void:
	_follow_enabled = false
	_follow_target = null

func _apply_composed_transform() -> void:
	var base_transform: Transform3D = Transform3D(_base_basis, _base_origin)
	global_transform = base_transform * _get_zoom_adjust()

func _process(_delta: float) -> void:
	if not _follow_enabled:
		return
	if not is_instance_valid(_follow_target):
		_follow_enabled = false
		_follow_target = null
		return
	var target_pos: Vector3 = _get_follow_target_position()
	var target_basis: Basis = global_transform.looking_at(target_pos, Vector3.UP).basis
	var blend: float = min(1.0, follow_rotation_speed * _delta)
	var blended_basis: Basis = global_transform.basis.slerp(target_basis, blend)
	global_transform = Transform3D(blended_basis, global_transform.origin)

func _look_at_current_player() -> void:
	assert(game_controller)
	assert(game_controller.game_state)
	assert(not game_controller.game_state.player_positions.is_empty())
	var player_index: int = game_controller.game_state.current_player_index
	assert(player_index >= 0 and player_index < game_controller.game_state.player_positions.size())
	var tile_index: int = game_controller.game_state.player_positions[player_index]
	_look_at_tile_slot(tile_index, player_index)

func _look_at_tile_slot(tile_index: int, player_index: int) -> void:
	assert(game_controller)
	assert(game_controller.game_state)
	assert(board_layout)
	assert(board_layout.has_method("get_tile_markers"))
	assert(tile_index >= 0 and tile_index < game_controller.game_state.tiles.size())
	var occupants: Array[int] = game_controller.game_state.tiles[tile_index].occupants
	var slot_index: int = occupants.find(player_index)
	assert(slot_index >= 0)
	var markers: Array[Marker3D] = board_layout.get_tile_markers(tile_index)
	assert(not markers.is_empty())
	assert(slot_index >= 0 and slot_index < markers.size())
	var target_pos: Vector3 = markers[slot_index].global_position
	var temp: Transform3D = Transform3D(Basis.IDENTITY, _base_origin)
	temp = temp.looking_at(target_pos, Vector3.UP)
	_base_basis = temp.basis
	_apply_composed_transform()


func _get_follow_target_position() -> Vector3:
	assert(_follow_target)
	var target_pos: Vector3 = _follow_target.global_position
	if follow_y_mode == FollowYMode.TABLE:
		var tiles: Array[Node3D] = board_layout.get_board_tiles()
		assert(not tiles.is_empty())
		target_pos.y = tiles[0].global_position.y
	else:
		target_pos.y = _follow_base_y
	return target_pos

func _bind_game_controller() -> void:
	if not game_controller.dice_roll_started.is_connected(_on_dice_roll_started):
		game_controller.dice_roll_started.connect(_on_dice_roll_started)
	if not game_controller.turn_ended.is_connected(_on_turn_ended):
		game_controller.turn_ended.connect(_on_turn_ended)
	if not game_controller.turn_started.is_connected(_on_turn_started):
		game_controller.turn_started.connect(_on_turn_started)

func _on_dice_roll_started(start_tile_index: int, end_tile_index: int, player_index: int) -> void:
	_cancel_dice_camera_sequence()
	var pawn: Node3D = _get_pawn(player_index)
	start_follow(pawn)
	var token: int = _dice_camera_token
	var board_tiles: Array = board_layout.get_board_tiles()
	var board_size: int = board_tiles.size()
	var steps: int = (end_tile_index - start_tile_index + board_size) % board_size
	var total_move_duration: float = (float(steps) * game_controller.pawn_wait_time_per_tile) + game_controller.pawn_delay_start_movement
	var delay: float = max(0.0, total_move_duration * prezoom_start_ratio)
	if delay > 0.0:
		_dice_camera_timer = get_tree().create_timer(delay)
		_dice_camera_timer.timeout.connect(_start_prezoom.bind(end_tile_index, token), CONNECT_ONE_SHOT)
	else:
		_start_prezoom(end_tile_index, token)

func _start_prezoom(end_tile_index: int, token: int) -> void:
	if token != _dice_camera_token:
		return
	tween_fov(_zoom_in_fov, prezoom_duration)
	if _dice_camera_timer:
		_dice_camera_timer = null
	if prezoom_duration > 0.0:
		_dice_camera_timer = get_tree().create_timer(prezoom_duration)
		_dice_camera_timer.timeout.connect(_finish_dice_roll_camera_transition.bind(end_tile_index, token), CONNECT_ONE_SHOT)
	else:
		_finish_dice_roll_camera_transition(end_tile_index, token)

func _finish_dice_roll_camera_transition(end_tile_index: int, token: int) -> void:
	if token != _dice_camera_token:
		return
	stop_follow()
	snap_to_tile(end_tile_index)
	set_zoom(true)

func _on_turn_ended(_next_player_index: int, _next_tile_index: int) -> void:
	_cancel_dice_camera_sequence()
	stop_follow()
	snap_to_tile(_next_tile_index, _next_player_index)
	set_zoom(false)

func _on_turn_started(player_index: int, tile_index: int) -> void:
	_cancel_dice_camera_sequence()
	stop_follow()
	snap_to_tile(tile_index, player_index)
	set_zoom(false)

func _get_pawn(player_index: int) -> Node3D:
	var pawns_root: Node = game_controller.pawns_root
	var pawn_name: String = "Pawn%d" % (player_index + 1)
	var pawn: Node3D = pawns_root.get_node(pawn_name)
	assert(pawn, "Pawn node not found: " + pawn_name)
	return pawn


func _get_zoom_adjust() -> Transform3D:
	return _zoom_out_relative.interpolate_with(_zoom_in_relative, _zoom_blend)

func _capture_pose_relatives() -> void:
	assert(pose_tile_ref)
	assert(pose_camera_zoom_out)
	assert(pose_camera_zoom_in)
	var tile_transform: Transform3D = pose_tile_ref.global_transform
	_zoom_out_relative = tile_transform.affine_inverse() * pose_camera_zoom_out.global_transform
	_zoom_in_relative = tile_transform.affine_inverse() * pose_camera_zoom_in.global_transform
	_zoom_out_fov = pose_camera_zoom_out.fov
	_zoom_in_fov = pose_camera_zoom_in.fov
	if pose_flip_yaw_180:
		var flip: Transform3D = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
		_zoom_out_relative = flip * _zoom_out_relative
		_zoom_in_relative = flip * _zoom_in_relative

func _set_base_transform(value: Transform3D) -> void:
	_base_basis = value.basis
	_base_origin = value.origin
	_apply_composed_transform()

func _set_zoom_blend(value: float) -> void:
	_zoom_blend = value
	_apply_composed_transform()

func _cancel_dice_camera_sequence() -> void:
	_dice_camera_token += 1
	if _dice_camera_timer:
		_dice_camera_timer = null
	if _fov_tween:
		_fov_tween.kill()
		_fov_tween = null
