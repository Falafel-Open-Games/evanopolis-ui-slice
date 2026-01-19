extends Node

const PLAYER_DARK_COLORS: Array[Color] = [
	Color("#555354"),
	Color("#d22b2b"),
	Color("#e16d25"),
	Color("#587d36"),
	Color("#488ddc"),
	Color("#a03dc1"),
]

const PLAYER_LIGHT_COLORS: Array[Color] = [
	Color("#b2b1b3"),
	Color("#ff8b79"),
	Color("#f8af46"),
	Color("#75d1a9"),
	Color("#79bdeb"),
	Color("#f48dff"),
]

const CITY_COLORS: Array[Color] = [
	Color("#2b2b2b"),
	Color("#404040"),
	Color("#595959"),
	Color("#737373"),
	Color("#8f8f8f"),
	Color("#adadad"),
]

const CITY_ORDER: Array[String] = [
	"Caracas",
	"Assuncion",
	"Ciudad del Este",
	"Minsk",
	"Irkutsk",
	"Rockdale",
]

const CITY_COLORS_BY_NAME: Dictionary = {
	"Caracas": Color("#2b2b2b"),
	"Assuncion": Color("#404040"),
	"Ciudad del Este": Color("#595959"),
	"Minsk": Color("#737373"),
	"Irkutsk": Color("#8f8f8f"),
	"Rockdale": Color("#adadad"),
}

func get_player_dark(index: int) -> Color:
	return PLAYER_DARK_COLORS[clamp(index, 0, PLAYER_DARK_COLORS.size() - 1)]

func get_player_light(index: int) -> Color:
	return PLAYER_LIGHT_COLORS[clamp(index, 0, PLAYER_LIGHT_COLORS.size() - 1)]
