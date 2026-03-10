class_name EventCardUi
extends Panel

@export var title_label: Label
@export var card_type_label: Label
@export var description_label: Label

func _ready() -> void:
    hide_card()

func show_card(event_card: EventCard) -> void:
    title_label.text = event_card.name
    card_type_label.text = str(Utils.CardEffectDeckType.keys()[event_card.deck_type]).to_upper()
    description_label.text = event_card.description
    self.visible = true

func hide_card() -> void:
    self.visible = false
