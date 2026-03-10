extends Node

enum TileType { START, INSPECTION, INCIDENT, PROPERTY, SPECIAL_PROPERTY, UNKNOWN }

enum CardEffectDeckType {
    BEAR,
    BULL
}

enum CardEffectType {
    PAY_FIAT_TO_BANK,
    PAY_BTC_TO_BANK,
    PAY_FIAT_TO_PLAYERS,
    PAY_BTC_TO_PLAYERS,
    RECEIVE_FIAT_FROM_BANK,
    RECEIVE_BTC_FROM_BANK,
    RECEIVE_FIAT_FROM_PLAYERS,
    RECEIVE_BTC_FROM_PLAYERS,
    GO_TO_JAIL,
    EXIT_JAIL_FREE,
    GAIN_MINER,
    LOSE_MINER
}

func sort_players_by_btc_desc(players: Array[PlayerData]) -> Array[PlayerData]:
    var reordered_players := players
    reordered_players.sort_custom(func(a, b):
        return a.bitcoin_balance > b.bitcoin_balance
    )

    return reordered_players
