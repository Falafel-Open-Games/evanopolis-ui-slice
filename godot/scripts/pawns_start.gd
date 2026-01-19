extends Node3D

@export var markers_root_path: NodePath

func _ready() -> void:
	_apply_marker_positions()

func _apply_marker_positions() -> void:
	var markers_root: Node = get_node_or_null(markers_root_path)
	if markers_root == null:
		return

	for index in range(1, 7):
		var marker: Node = markers_root.get_node_or_null("Marker%d" % index)
		var pawn: Node = get_node_or_null("Pawn%d" % index)
		if marker is Marker3D and pawn is Node3D:
			pawn.global_transform = marker.global_transform
