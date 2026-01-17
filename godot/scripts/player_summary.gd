extends FoldableContainer

const PlayerColors:Array[Color] = [
	"#00a2df",
	"#df00c2", 
	"#df0004", 
	"#df8000",
	"#dddf00",
	"#00df34",
]

@export_range(0, 5, 1) var player_index = 0

func _ready() -> void:
	# set panel font color based on player index
	self.add_theme_color_override("font_color", PlayerColors[player_index])
	self.add_theme_color_override("collapsed_font_color", PlayerColors[player_index])
	
	# set panel title based on player index
	self.title = "Player %d" % [player_index + 1]
