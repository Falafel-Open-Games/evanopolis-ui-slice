@tool
extends Node3D

@export var base_color: Color = Color("#555354"):
	set(value):
		base_color = value
		if is_inside_tree():
			_apply_colors()

@export var accent_color: Color = Color("#b2b1b3"):
	set(value):
		accent_color = value
		if is_inside_tree():
			_apply_colors()

@onready var base_mesh: MeshInstance3D = %Base
@onready var stem_mesh: MeshInstance3D = %Stem
@onready var cap_mesh: MeshInstance3D = %Cap

func _ready() -> void:
	_apply_colors()

func _apply_colors() -> void:
	_set_mesh_color(base_mesh, base_color)
	_set_mesh_color(stem_mesh, base_color)
	_set_mesh_color(cap_mesh, accent_color)

func _set_mesh_color(mesh: MeshInstance3D, color: Color) -> void:
	if mesh == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
