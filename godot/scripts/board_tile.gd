@tool
class_name BoardTile
extends Node3D

var _tile_color: Color = Color.WHITE

@export var tile_color: Color = Color.WHITE:
	get:
		return _tile_color
	set(value):
		_tile_color = value
		if is_inside_tree():
			_apply_color()

func _ready() -> void:
	_apply_color()

func _apply_color() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = _tile_color
	for mesh in find_children("*", "MeshInstance3D", true, false):
		if mesh is MeshInstance3D:
			mesh.material_override = material
