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

    TurnStarted --> AwaitingRoll: no pending action
    TurnStarted --> AwaitingPendingAction: pending action from snapshot/reconnect
    AwaitingRoll --> ResolvingRoll: rpc_roll_dice
    ResolvingRoll --> ResolvingMove: rpc_dice_rolled
    ResolvingMove --> TileLanded: rpc_pawn_moved + rpc_tile_landed
    TileLanded --> PendingActionSet: server stores pending action
    PendingActionSet --> AwaitingPendingAction: prompt current player
    AwaitingPendingAction --> ResolvingBuy: rpc_buy_property
    AwaitingPendingAction --> ResolvingPayToll: rpc_pay_toll
    AwaitingPendingAction --> ResolvingEndTurn: rpc_end_turn
    ResolvingBuy --> TurnAdvanced: rpc_property_acquired + rpc_turn_started
    ResolvingPayToll --> TurnAdvanced: rpc_toll_paid + rpc_turn_started
    ResolvingEndTurn --> TurnAdvanced: rpc_turn_started
    TurnAdvanced --> TurnStarted: next player

    AwaitingRoll --> IntentQueued: rpc_* outside-turn intent accepted
    AwaitingPendingAction --> IntentQueued: rpc_* outside-turn intent accepted
    IntentQueued --> AwaitingRoll: effect deferred to deterministic boundary

    AwaitingRoll --> Timeout: turn timer expired
    AwaitingPendingAction --> Timeout: action timer expired
    Timeout --> ResolvingEndTurn: apply penalty/default + advance turn

    state ReconnectSync {
      [*] --> JoinAccepted
      JoinAccepted --> SyncRequested: rpc_sync_request(last_applied_seq)
      SyncRequested --> SnapshotApplied: rpc_state_snapshot
      SnapshotApplied --> SyncComplete: rpc_sync_complete
      SyncComplete --> [*]
    }
```

Notes:
- "Pending action" is authoritative server state and gates which action RPCs are valid.
- v0 action set is `buy_or_end_turn`, `pay_toll`, and `end_turn`; incident/inspection branches are added later.
- Outside-turn actions are recorded as deferred intents and never mutate the currently resolving turn.
- Deferred intents activate only at a deterministic boundary (`effective_from_turn` / equivalent rule).
- Timeout behavior and penalties should be defined in `godot2/DESIGN.md`.
