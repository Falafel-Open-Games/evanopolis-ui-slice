@tool
class_name BoardTile
extends Node3D

var _tile_color: Color = Color.WHITE
var _color_material: StandardMaterial3D = StandardMaterial3D.new()
var _top_material: Material
var _bottom_material: Material
var _base_mesh_rotation: Vector3
var _owned_visual: bool = false

@export var tile_color: Color = Color.WHITE:
	get:
		return _tile_color
	set(value):
		_tile_color = value
		if is_inside_tree():
			_apply_color()

@export var mesh_root: Node3D
@export var top_face: MeshInstance3D
@export var bottom_face: MeshInstance3D
@export var side_mesh: MeshInstance3D

@export var top_material: Material:
	get:
		return _top_material
	set(value):
		_top_material = value
		if is_inside_tree():
			_apply_face_materials()

@export var bottom_material: Material:
	get:
		return _bottom_material
	set(value):
		_bottom_material = value
		if is_inside_tree():
			_apply_face_materials()

func _ready() -> void:
	assert(mesh_root)
	assert(top_face)
	assert(bottom_face)
	assert(side_mesh)
	_base_mesh_rotation = mesh_root.rotation
	_apply_color()
	_apply_face_materials()
	_apply_owned_visual()

func set_owned_visual(owned: bool) -> void:
	_owned_visual = owned
	_apply_owned_visual()

func _apply_color() -> void:
	_color_material.albedo_color = _tile_color
	side_mesh.material_override = _color_material
	_apply_face_materials()

func _apply_face_materials() -> void:
	var top_override: Material = _top_material
	var bottom_override: Material = _bottom_material
	if top_override == null:
		top_override = _color_material
	if bottom_override == null:
		bottom_override = _color_material
	top_face.set_surface_override_material(0, top_override)
	bottom_face.set_surface_override_material(0, bottom_override)

func _apply_owned_visual() -> void:
	var z_offset: float = PI if _owned_visual else 0.0
	mesh_root.rotation = _base_mesh_rotation + Vector3(0.0, 0.0, z_offset)
