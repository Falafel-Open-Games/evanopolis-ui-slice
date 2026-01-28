class_name CameraTileRig
extends Camera3D

@export var board_layout: Node
@export var zoom_out_fov: float = 55.0
@export var zoom_in_fov: float = 15.0
@export var zoom_in_height_offset: float = -0.11
@export var zoom_in_distance_offset: float = -0.1
@export var zoom_in_pitch_degrees: float = 0.0

var _tile0_to_camera: Transform3D = Transform3D.IDENTITY
var _has_offset: bool = false
var _base_basis: Basis = Basis.IDENTITY
var _base_origin: Vector3 = Vector3.ZERO
var _zoom_blend: float = 0.0

func _ready() -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	_set_base_transform(global_transform)
	set_zoom(false)
	call_deferred("_capture_base_offset")

func snap_to_tile(tile_index: int) -> void:
	assert(board_layout)
	assert(board_layout.has_method("get_board_tiles"))
	if not _has_offset:
		_capture_base_offset()
	assert(_has_offset)
	var tiles: Array[Node3D] = board_layout.get_board_tiles()
	assert(tile_index >= 0 and tile_index < tiles.size())
	var tile: Node3D = tiles[tile_index]
	_set_base_transform(tile.global_transform * _tile0_to_camera)

func set_zoom(is_zoom_in: bool) -> void:
	var target_fov: float = zoom_in_fov if is_zoom_in else zoom_out_fov
	var target_blend: float = 1.0 if is_zoom_in else 0.0
	fov = target_fov
	_set_zoom_blend(target_blend)

func _apply_composed_transform() -> void:
	var base_transform: Transform3D = Transform3D(_base_basis, _base_origin)
	global_transform = base_transform * _get_zoom_adjust()


func _get_zoom_adjust() -> Transform3D:
	var pitch: float = deg_to_rad(zoom_in_pitch_degrees) * _zoom_blend
	var height_offset: float = zoom_in_height_offset * _zoom_blend
	var distance_offset: float = zoom_in_distance_offset * _zoom_blend
	var basis: Basis = Basis(Vector3(1.0, 0.0, 0.0), pitch)
	var origin: Vector3 = Vector3(0.0, height_offset, distance_offset)
	return Transform3D(basis, origin)

func _capture_base_offset() -> void:
	var tiles: Array[Node3D] = board_layout.get_board_tiles()
	assert(not tiles.is_empty())
	var tile: Node3D = tiles[0]
	var previous_blend: float = _zoom_blend
	_zoom_blend = 0.0
	_apply_composed_transform()
	_tile0_to_camera = tile.global_transform.affine_inverse() * global_transform
	_zoom_blend = previous_blend
	_apply_composed_transform()
	_set_base_transform(tile.global_transform * _tile0_to_camera)
	_has_offset = true

func _set_base_transform(value: Transform3D) -> void:
	_base_basis = value.basis
	_base_origin = value.origin
	_apply_composed_transform()

func _set_base_origin(value: Vector3) -> void:
	_base_origin = value
	_apply_composed_transform()

func _set_zoom_blend(value: float) -> void:
	_zoom_blend = value
	_apply_composed_transform()
