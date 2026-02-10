# Server State Machine (Headless)

This diagram is a high-level guide for prioritizing unit tests and RPCs. Each transition should map to at least one test.

```mermaid
stateDiagram-v2
    [*] --> Boot
    Boot --> ConfigLoaded: load configs
    ConfigLoaded --> WaitingForPlayers: match created
    WaitingForPlayers --> WaitingForPlayers: rpc_join (reject invalid)
    WaitingForPlayers --> WaitingForPlayers: rpc_join_accepted + rpc_player_joined
    WaitingForPlayers --> GameStarted: seats filled
    GameStarted --> TurnStarted: rpc_game_started + rpc_turn_started

    TurnStarted --> AwaitingRoll: current player prompt
    AwaitingRoll --> ResolvingRoll: rpc_roll_dice
    ResolvingRoll --> ResolvingMove: rpc_dice_rolled
    ResolvingMove --> TileLanded: rpc_pawn_moved + rpc_tile_landed
    TileLanded --> AwaitingTileAction: if required action
    TileLanded --> TurnEnd: if no required action
    AwaitingTileAction --> TurnEnd: rpc_* action resolved
    TurnEnd --> TurnStarted: next player

    AwaitingRoll --> Timeout: turn timer expired
    AwaitingTileAction --> Timeout: action timer expired
    Timeout --> TurnEnd: apply penalty + advance turn
```

Notes:
- "Required action" includes buy/skip, incident resolution, inspection decisions, etc.
- Timeout behavior and penalties should be defined in `godot2/DESIGN.md`.
