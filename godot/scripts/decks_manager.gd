class_name DecksManager
extends Node

var bear_deck: Array[EventCard] = []
var bull_deck: Array[EventCard] = []

func _ready():
    bear_deck = _load_deck("res://cards/bear/")
    bull_deck = _load_deck("res://cards/bull/")
    shuffle_decks()

func _load_deck(folder_path: String) -> Array[EventCard]:
    var deck: Array[EventCard] = []

    for file_name in DirAccess.get_files_at(folder_path):
        if not file_name.ends_with(".tres"):
            continue

        var card: EventCard = load(folder_path + file_name)
        if card == null:
            continue

        for i in card.copies:
            deck.append(card)  # same data, multiple slots
    return deck

func shuffle_decks():
    bear_deck.shuffle()
    bull_deck.shuffle()

func draw_bear_card() -> EventCard:
    if bear_deck.is_empty():
        bear_deck.shuffle()
    var card: EventCard = bear_deck.pop_front()
    bear_deck.append(card)
    return card

func draw_bull_card() -> EventCard:
    if bull_deck.is_empty():
        bull_deck.shuffle()
    var card: EventCard = bull_deck.pop_front()
    bull_deck.append(card)
    return card
