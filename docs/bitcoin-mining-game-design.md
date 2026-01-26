# Bitcoin Mining Game Design (Draft)

Reference: brainstorm notes in `docs/bitcoin-mining-rules-exploration.md`.

## Board & Players
- The board is made of tiles that represent properties in cities, with corner tiles as incident tiles marking 17.5k-block checkpoints.
- Tiles are arranged in a hexagon format.
- The game supports 2 to 6 players.
- The starting tile is the Halving tile (replaces "go"/"salida").
- The starting tile is double-sided (Halving / Fiat Inflation); the first player to pass or land on it each cycle flips it.
- The corner tiles mark 17.5k, 35k, 52.5k, 70k, 87.5k, and 105k blocks.
  - Corner 1: Halving / Fiat Inflation (start tile).
  - Corner 4: Inspection (opposite the start tile).
  - Corners 2, 3, 5, 6: incidents (bull/bear).

## Goal
- The goal is to collect as much BTC as possible within 420,000 blocks.
  - Players earn BTC by constructing mining stations on their properties and collecting payouts.

## Game Setup & Start
- Each player starts with 1,000,000 fiat tokens and 1 BTC.
- Each player starts with no properties and no mining stations.
- Fiat and BTC payments are allowed in all cycles; BTC payments are priced at a 10% discount using the base (cycle 1) fiat price.
- Exchange rate reference for UI: 1 BTC = 100,000 fiat.

## Buying Properties & Mining Rigs
- Properties are bought with fiat; regular properties can host up to 4 miner batches.
- Property prices scale by tier (20k/50k/80k/110k/150k/200k).
- Miner batches cost 320k fiat per unit.
- Each miner piece represents a batch of 50 hydro miners (e.g., Antminer S21 Hydro).
- Properties and miner batches can be bought with BTC at a 10% discount.

## Owned Property Landing
- When landing on an owned property, the visitor pays a fiat energy toll.
- The owner receives a BTC payout for block discovery equal to `base * miner_batches` on that property.
- Tolls: fiat energy toll = 10% of property price + 2.5% of property price per miner batch.
  - BTC tolls use the same 10% discount as other BTC prices, anchored to base (cycle 1) fiat values.

## Incidents
- Landing exactly on a corner incident tile triggers an incident; the tile flip determines bull or bear.
- The game runs for four cycles; the start tile flip alternates cycle effects:
  - Halving side: base payout is halved for that cycle.
  - Fiat Inflation side: fiat prices and energy tolls inflate by 10% for that cycle.
  - Inflation persists; once increased, fiat prices do not drop on later halving cycles.
  - BTC prices remain anchored to base (cycle 1) fiat values.

## Inspection
- Landing on Inspection blocks the player's mining payouts.
- To clear Inspection: pay a fee or roll doubles on 2d6.

## Payouts
- Payout rounds trigger when a player lands on a property; the property owner earns BTC.
- Total payout floats with miner counts; no fixed pot to split.
- Base payout is 2.0 BTC per miner per payout in cycle 1-2, halved to 1.0 BTC in cycle 3-4.

## Win Conditions
- The game ends after cycle 4.
- Alternate win: at the end of any full round, if any player has 20 BTC or more, the game ends.

## Example Property Card (Caracas, Tier 1)
```
+------------------------------------------------------+
|                    CARACAS (Tier 1)                  |
|              Max Miner Batches: 3                    |
+-------------------+-----------+----------------------+
| Cycle             | Fiat Price| Energy Toll (10%)     |
+-------------------+-----------+----------------------+
| 1 (Halving)       | 20,000    | 2,000                |
| 2 (Inflation +10%)| 22,000    | 2,200                |
| 3 (Halving)       | 22,000    | 2,200                |
| 4 (Inflation +10%)| 24,200    | 2,420                |
+-------------------+-----------+----------------------+
| BTC Payout per Miner Batch when landed on:           |
| Cycle 1: 2.0 BTC                                   |
| Cycle 2: 2.0 BTC                                   |
| Cycle 3: 1.0 BTC                                   |
| Cycle 4: 1.0 BTC                                   |
+------------------------------------------------------+
```
