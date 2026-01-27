# Bitcoin Mining Game Design

## Goal
- The goal is to collect as much BTC as possible within 4 cycles.
  - Players earn BTC by constructing mining stations on their properties and collecting payouts.

## Board & Players
- The game supports 2 to 6 players.
- Movement happens in turns as the result of 2d6 dice rolls.
- The board is organized with tiles forming a hexagon shape.
- Two types of tiles exist: squares (properties) and angled corners (incidents).
- Two decks of event cards (Bear and Bull) should be shuffled separately and placed on different spots on the table.

### Board Setup
- The initial tile is the incident `Start`.
    - From that, a sequence of tiles forming city sides (of size `n`) and incident corners builds the full hexagon loop in this order:
        - `Caracas` x `n`,
        - `Bear`,
        - `Assuncion` x `n`,
        - `Bear`,
        - `Ciudad del Este` x `n`,
        - `Inspection`,
        - `Minsk` x `n`,
        - `Bear`,
        - `Irkutsk` x `n`,
        - `Bear`,
        - `Rockdale` x `n`.
    - The value of `n` (3-5) is chosen before match start. Larger boards lead to longer games:
        - 3 for a small board of 24 tiles, or
        - 4 for a medium board of 30 tiles, or
        - 5 for a large board of 36 tiles. See diagram 1.

[IMAGE TBD]
(Diagram 1: Example of a medium board in a 4 players game)

### Players Setup at Start
- Each player starts with `1,000,000` `fiat tokens` and `0` `BTC`.
- Each player starts with `no properties` and `no miner batches`.

## Buying Properties & Mining Rigs
- Properties are bought with fiat; regular properties can host up to `4 miner batches`.
- Property prices scale by city tier:
  - Caracas 20k, Assuncion 50k, Ciudad del Este 80k, Minsk 110k, Irkutsk 150k, Rockdale 200k.
- Miner batches cost `320k fiat per unit`.
   - Each miner piece represents a batch of 50 hydro miners.
- Prices inflate on fiat inflation cycles; inflation is cumulative.
- A property can only be purchased when you land on it.

### Miner Batch Orders (Flow)
- Any player can place miner batch orders at any time.
- Confirming an order deducts the fiat balance immediately.
- Miner batches do not appear on properties until the current turn ends; all pending orders are applied at the end of each turn (not just the owner's turn).

## Owned Property Landing

### Energy Toll
- When landing on an owned property, the visitor pays a fiat `energy toll` to the property owner.
- Tolls: fiat energy toll = 10% of property price + 2.5% of property price per miner batch.
- If the visitor cannot pay, they are immediately moved to `Inspection` and their turn ends.
  - The owner still receives the BTC payout for the landing on the original property; the unpaid toll is not transferred.
  - The player must clear Inspection normally on their next turn.

### Payouts
- When landing on an owned property, the owner receives a `BTC payout` for block discovery equal to `base * miner_batches` on that property. This BTC is the network subsidy, comes from the network, is not a transfer from other player.
- Payout rounds trigger when a player lands on a property; the property owner earns BTC.
- Base payout is 2.0 BTC per miner per payout in cycle 1-2, halved to 1.0 BTC in cycle 3-4.
- Payout is triggered regardless of the landing player being the owner; all landings generate a payout.

## Incidents
- The game runs for four cycles. A new cycle begins when the first player passes over Start after game start:
  - Cycle 1 starts at game start.
  - Cycle 2 starts when the first player passes over Start for the first time.
  - Cycle 3 starts when the first player passes over Start for the second time.
  - Cycle 4 starts when the first player passes over Start for the third time.
- Cycle 1 starts with the Start tile showing `Start`.
- The start tile is double-sided (`Start` / `Fiat Inflation`).
  - The first player to pass over Start to begin a new cycle flips the Start tile.
  - The new face applies to the new cycle that just began.
  - If it shows Fiat Inflation, fiat prices and energy tolls inflate by 10% for that cycle.
  - Inflation persists; once increased, fiat prices do not drop in later cycles.
- Landing exactly on a `Bull`/`Bear` incident tile triggers an incident (card draw of corresponding deck); the tile face determines bull or bear.
  - Passing over a `Bear` tile flips it to change the effect for the next player who lands on it. Landing exactly does not flip it.

### Flipping tiles
- The Start tile is double-sided (`Start` / `Fiat Inflation`).
- The `Bear` tiles are also double-sided (`Bear` / `Bull`).
- The middle (4th) corner, `Inspection`, does not flip.
- Property tiles have price information on the bottom side and can be flipped to represent an owned property.

## Inspection
- Landing on Inspection blocks the player's mining payouts from their properties.
- Energy tolls are still collected while in Inspection.
- To clear Inspection: pay a fee of 150k fiat or roll doubles on 2d6.

## Win Conditions
- The game ends after cycle 4; the player with the most BTC wins.
- Alternate win: at the end of any full round (each player has taken one turn), if any player has 20 BTC or more, the game ends and the player with the most BTC wins.

## Glossary
- Pass over: when a pawn moves across a tile during movement without landing exactly on it. Landing exactly does not count as passing over.

## Example Property Card (Caracas, Tier 1)
```
+------------------------------------------------------+
|                    CARACAS (Tier 1)                  |
|              Max Miner Batches: 4                    |
+-------------------+-----------+----------------------+
| Cycle             | Fiat Price| Energy Toll (base)    |
+-------------------+-----------+----------------------+
| 1 (Start)         | 20,000    | 2,000                |
| 2 (Inflation +10%)| 22,000    | 2,200                |
| 3 (Start)         | 22,000    | 2,200                |
| 4 (Inflation +10%)| 24,200    | 2,420                |
+-------------------+-----------+----------------------+
| Energy toll values shown assume 0 miner batches.     |
| Add 2.5% of price per miner batch.                   |
| BTC Payout per Miner Batch when landed on:           |
| Cycle 1: 2.0 BTC                                   |
| Cycle 2: 2.0 BTC                                   |
| Cycle 3: 1.0 BTC                                   |
| Cycle 4: 1.0 BTC                                   |
+------------------------------------------------------+
```
