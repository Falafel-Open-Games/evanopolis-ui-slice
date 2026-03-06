extends Resource
class_name EventCard

@export var name: String
@export_multiline var description: String
@export var deck_type: Utils.CardEffectDeckType
@export var effect_type: Utils.CardEffectType
@export var amount: float = 0.0
@export var affects_all_players: bool = false  # for player‑to‑player effects
