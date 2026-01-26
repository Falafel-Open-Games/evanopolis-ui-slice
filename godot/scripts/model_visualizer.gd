extends Node3D

@export var model_scene: PackedScene
@onready var color_picker: ColorPicker = $ColorPicker
@onready var model_root: Node3D = $ModelRoot

func _ready():
	# Instance the model scene if not already in the editor
	if model_scene and model_root.get_child_count() == 0:
		var instance = model_scene.instantiate()
		model_root.add_child(instance)

	# After the model is in the tree, set up per-mesh materials
	call_deferred("_init_swappable_materials")
	color_picker.color_changed.connect(_on_color_changed)


func _init_swappable_materials():
	# For each mesh in the group, duplicate its material so it has its own instance
	for node in get_tree().get_nodes_in_group("color_swappable_mesh"):
		if not model_root.is_ancestor_of(node):
			continue
		if not (node is MeshInstance3D):
			continue

		var mesh := node as MeshInstance3D
		var surface_count := mesh.mesh.get_surface_count()
		for surface in range(surface_count):
			var mat := mesh.get_surface_override_material(surface)
			if mat == null:
				mat = mesh.mesh.surface_get_material(surface)
			if mat == null:
				continue

			# Duplicate material so this mesh has its own copy
			var mat_copy := mat.duplicate()
			mesh.set_surface_override_material(surface, mat_copy)

	# Apply initial color
	_apply_color_to_all_meshes(color_picker.color)


func _on_color_changed(new_color: Color):
	_apply_color_to_all_meshes(new_color)


func _apply_color_to_all_meshes(new_color: Color):
	for node in get_tree().get_nodes_in_group("color_swappable_mesh"):
		if not model_root.is_ancestor_of(node):
			continue
		if not (node is MeshInstance3D):
			continue

		var mesh := node as MeshInstance3D
		var surface_count := mesh.mesh.get_surface_count()
		for surface in range(surface_count):
			var mat := mesh.get_surface_override_material(surface)
			if mat == null:
				mat = mesh.mesh.surface_get_material(surface)
			if mat == null:
				continue

			if mat is StandardMaterial3D:
				mat.albedo_color = new_color  # direct color control [web:69][web:64]
			elif mat is ShaderMaterial:
				# If you have a custom shader, expose a uniform, e.g. "tint_color"
				if mat.get_shader_parameter_list().has("tint_color"):
					mat.set_shader_parameter("tint_color", new_color)
