extends Camera3D

@export var camera_positions: Array[Marker3D]
@export var move_duration: float = 1.5
@export var rotation_speed: float = 5.0  # Speed of the physical camera rotation
@export var focus_damping: float = 10.0  # How fast the "eye" catches up to the target (Higher = Tighter)
@export var debug_target_node: Node3D

var _target_node: Node3D = null
var _is_following: bool = false
var _current_tween: Tween
var _current_focus_point: Vector3

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			move_to_position(0)
		if event.keycode == KEY_2:
			move_to_position(1)
		if event.keycode == KEY_3:
			move_to_position(2)
		if event.keycode == KEY_S:
			set_follow_target(debug_target_node)

func _process(delta: float) -> void:
	if _is_following and is_instance_valid(_target_node):
		var real_target_pos = _target_node.global_position
		_current_focus_point = _current_focus_point.lerp(real_target_pos, focus_damping * delta)

		# Safety Check (Prevent looking at self)
		if global_position.distance_squared_to(_current_focus_point) > 0.001:
			var target_xform = global_transform.looking_at(_current_focus_point, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_xform.basis, rotation_speed * delta)

func set_follow_target(new_target: Node3D) -> void:
	_target_node = new_target

	if new_target == null:
		_is_following = false
	else:
		_is_following = true
		_current_focus_point = new_target.global_position

func move_to_position(index: int) -> void:
	if index < 0 or index >= camera_positions.size():
		return

	var target_marker = camera_positions[index]

	if _current_tween:
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.set_ease(Tween.EASE_IN_OUT)
	_current_tween.set_trans(Tween.TRANS_CUBIC)

	if is_instance_valid(_target_node):
		_is_following = true
		_current_tween.tween_property(self, "global_position", target_marker.global_position, move_duration)
	else:
		_is_following = false
		_current_tween.set_parallel(true)
		_current_tween.tween_property(self, "global_position", target_marker.global_position, move_duration)
		_current_tween.tween_property(self, "global_rotation", target_marker.global_rotation, move_duration)
