extends Node

enum TileType { START, INSPECTION, INCIDENT, PROPERTY, SPECIAL_PROPERTY, UNKNOWN }

func sort_players_by_btc_desc(players: Array[PlayerData]) -> Array[PlayerData]:
    var reordered_players := players
    reordered_players.sort_custom(func(a, b):
        return a.bitcoin_balance > b.bitcoin_balance
    )

    return reordered_players
