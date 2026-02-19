@tool
class_name BoardTile
extends Node3D

var _tile_color: Color = Color.WHITE
var _color_material: StandardMaterial3D = StandardMaterial3D.new()
var _top_material: Material
var _bottom_material: Material
var _base_mesh_rotation: Vector3
var _owned_visual: bool = false
var _miner_instances: Array[Node3D] = []

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
@export var miner_markers: Node3D
@export var miner_scene: PackedScene = preload("res://meshes/antminer_s21_hydro.tscn")
@export var mesh_owner: MeshInstance3D

const MINER_SCALE: float = 0.003

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
    assert(miner_markers)
    _base_mesh_rotation = mesh_root.rotation
    _apply_color()
    _apply_face_materials()
    _apply_owned_visual()

    if mesh_owner:
        # Make the material unique to this instance
        var mat := mesh_owner.get_active_material(0).duplicate()
        mesh_owner.set_surface_override_material(0, mat)
        mesh_owner.visible = false

func set_owned_visual(owned: bool, owner_color: Color = Color(0,0,0,0)) -> void:
    _owned_visual = owned
    if mesh_owner:
        mesh_owner.visible = owned
        if owned:
            var mat := mesh_owner.get_active_material(0) as StandardMaterial3D
            if mat:
                mat.albedo_color = owner_color
    _apply_owned_visual()

func set_miner_batches(count: int, miner_color: Color) -> void:
    assert(miner_markers)
    _clear_miners()
    if count <= 0:
        return
    assert(miner_scene)
    var slots: Array[Marker3D] = _get_miner_slots()
    var max_count: int = min(count, slots.size())
    for index in range(max_count):
        var slot: Marker3D = slots[index]
        var instance: Node3D = miner_scene.instantiate() as Node3D
        assert(instance)
        instance.scale = Vector3.ONE * MINER_SCALE
        slot.add_child(instance)
        _apply_miner_color(instance, miner_color)
        _miner_instances.append(instance)

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

func _clear_miners() -> void:
    for instance in _miner_instances:
        if instance != null:
            instance.queue_free()
    _miner_instances = []

func _get_miner_slots() -> Array[Marker3D]:
    var slots: Array[Marker3D] = []
    for child in miner_markers.get_children():
        var marker: Marker3D = child as Marker3D
        assert(marker)
        slots.append(marker)
    slots.sort_custom(_sort_markers_by_index)
    return slots

func _sort_markers_by_index(a: Marker3D, b: Marker3D) -> bool:
    return _extract_marker_index(a.name) < _extract_marker_index(b.name)

func _extract_marker_index(marker_name: String) -> int:
    var digits: String = ""
    for i in range(marker_name.length() - 1, -1, -1):
        var char: String = marker_name.substr(i, 1)
        if char.is_valid_int():
            digits = char + digits
        else:
            break
    if digits.is_empty():
        return 0
    return int(digits)

func _apply_miner_color(root: Node, miner_color: Color) -> void:
    for child in root.get_children():
        if child is MeshInstance3D and child.is_in_group("color_swappable_mesh"):
            var mesh: MeshInstance3D = child as MeshInstance3D
            var surface_count: int = mesh.mesh.get_surface_count()
            for surface in range(surface_count):
                var material: Material = mesh.get_surface_override_material(surface)
                if material == null:
                    material = mesh.mesh.surface_get_material(surface)
                if material == null:
                    continue
                var material_copy: Material = material.duplicate()
                mesh.set_surface_override_material(surface, material_copy)
                if material_copy is StandardMaterial3D:
                    var standard_material: StandardMaterial3D = material_copy as StandardMaterial3D
                    standard_material.albedo_color = miner_color
                elif material_copy is ShaderMaterial:
                    var shader_material: ShaderMaterial = material_copy as ShaderMaterial
                    if shader_material.get_shader_parameter_list().has("tint_color"):
                        shader_material.set_shader_parameter("tint_color", miner_color)
        _apply_miner_color(child, miner_color)
