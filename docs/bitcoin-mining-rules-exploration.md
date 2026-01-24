# Bitcoin Mining Themed Rules (Exploration Draft)

## Brainstorm

Goal: translate Bitcoin principles (no central bank, permissionless mining, fixed
supply, difficulty adjustment) into a fun board-game loop. This is a side quest
separate from `docs/spec.md`.

### Core Metrics
- Fiat: cash to buy hardware, pay energy, and survive volatility.
- Hashrate: mining power; increases block reward share.
- Bitcoin: score currency; win condition could be highest BTC at end.

### Game Loop Concept
- Players start with fiat only.
- Each loop around the board represents a new block found.
- On block payout, each player receives BTC proportional to hashrate.
- Fiat has no "central bank" payout; only earned via converting BTC or events.

### Board Structure (Thematic)
- Mining Shops: buy ASICs or upgrade efficiency (hashrate per fiat).
- Energy Contracts: lock lower power cost for N turns; risk of outages.
- Logistics/Customs: delay hardware delivery or add import tax.
- Market Swings: BTC/fiat price moves; sell BTC to fund expansion.
- Difficulty Adjustment: global event that reduces BTC per hashrate if too much
  hashrate is online.
- Fork/Policy Debates: optional events that change rules for a few turns.

### Mining Mechanics
- Block reward = base subsidy + fees (fees from an event deck).
- Reward split = each player's hashrate / total network hashrate.
- Halving: every X loops, base subsidy halves.
- Difficulty: if total hashrate grows past a threshold, reward per hash drops.
- Payout round trigger (alternate): landing on a property triggers a BTC payout round for that property owner.
- Milestone tiles are incident-only; landing exactly on a milestone triggers bull/bear based on the face up.
- Payout model (base mode): the property owner earns `miner_batches * base` on payout rounds.
- Base payout draft: 2.0 BTC per miner batch per payout.
- Total payout floats with miner counts; no fixed pot to split.

#### 2d6 Probabilities (Optional Add-on)
```
Sum  Ways  Probability
2      1    2.78%
3      2    5.56%
4      3    8.33%
5      4   11.11%
6      5   13.89%
7      6   16.67%
8      5   13.89%
9      4   11.11%
10     3    8.33%
11     2    5.56%
12     1    2.78%
```

### Pooling & Routing Hashrate (Optional Add-on)
- Pooling is a potential advanced mode; base rules skip pools for simplicity.
- Fixed pools (A, B, C); players point miners to one pool.
- Rank pools by miners; apply 2d6 upset roll to adjust order:
  - 2: miracle swap (#3 / #1 / #2)
  - 3–4: upset swap (#2 / #1 / #3)
  - 5–12: baseline (#1 / #2 / #3)
- Pool payouts use rank multipliers: #1 x3, #2 x2, #3 x1 per miner.
- Pool fee: #1 pool pays a flat -1 per miner (or equivalent token fee).

### Hosting & Infrastructure
- Properties can represent container sites or hosting lots.
- Owners can host their own rigs and optionally rent space to others.
- Hosting provides fiat income but adds upkeep and risk (e.g., outages, disputes).
- Keep a simple cap on hosted rigs per site to avoid bookkeeping overload (4 miner batches).
- Owned property landing: pay the owner a choice of power toll (fiat) or pool tax (BTC) to choose which balance takes the hit.
- Power toll scales by property tier in fiat; pool tax is a fixed BTC amount per miner on the property.
- Tolls: fiat power toll = 10% of property price; BTC pool tax = 0.05 BTC per miner.

### Energy Prices & Incentives
- Energy price can vary by site or by global market.
- Incentives can lower energy cost for a few loops, with tradeoffs.
- Contracts vs spot: lock in a rate or ride volatility.
- Energy shocks can penalize high-hashrate players to keep risk meaningful.

### Economy & Risk
- Energy cost paid each loop per unit of hashrate.
- Hardware decay: ASICs lose efficiency after N loops unless upgraded.
- Fiat scarcity: no free money; fiat only from initial stack, selling BTC, or
  explicit event rewards (e.g., "found a buyer").
- Custody risk: optional event where careless storage loses BTC.
- Fiat prices and energy tolls increase by 10% only on cycles where the start tile shows 105,000.

### Win Conditions (Options)
- Highest BTC after N loops.
- First to reach target BTC.
- Hybrid: BTC primary, fiat tiebreaker.

### Open Questions
- How to keep pacing fast with proportional payouts?
- Should there be a "mining pool" option to smooth variance?
- How punitive should energy and hardware decay be?
- How to represent difficulty and halving in UI without heavy math?

### Game Length (Exploration)
- Real-world year is ~52,560 blocks; use 210,000 as a fixed default (2 cycles), or 420,000 for 4 cycles.
- Decide later how a "block" maps to in-game time or turns.
- Constraint: with 6 players on a 36-tile board, max game length should be under 1 hour.
- If one player turn equals one day, then a turn is ~144 blocks (10 min per block).
- A 4-cycle match is a possible reference length for pacing.
- Hex corners could represent time clusters; each corner = 17,500 blocks.
- One full cycle would equal 105,000 blocks under this mapping.
- Start tile flip: the start tile has two sides (Halving / Fiat Inflation); the first player to pass or land on it each cycle flips it. Halving side halves base payouts for that cycle; Fiat Inflation side applies 10% fiat inflation for that cycle.

### Game Setup & Start (Exploration)
- Initial fiat suggestion: 1,200,000 tokens per player (12 BTC at 100k/BTC).
- Draft pricing scale (6 tiers): 20k, 50k, 80k, 110k, 150k, 200k fiat.
- Miner cost draft: 320k fiat per miner.
- Early-cycle target: afford ~2 properties + ~4 miners by the first few payouts.
- Miner piece represents a batch of 50 hydro miners (e.g., Antminer S21 Hydro).
- Cycle 1 payments are fiat-only; cycle 2+ allows BTC payments at a 10% discount.
- Fiat prices increase 10% only on 105,000 cycles; BTC payments are 10% cheaper than fiat.
### Turn Time Heuristics (Exploration)
- Baseline: 6 players use a 0:30 turn cap.
- To match 6-player match length, use 0:45 for 4 players and 1:30 for 2 players.
- Target match length: ~40-65 minutes for four full loops of the hexagon board.
- Estimated match time table (4 cycles, avg roll 7):

```
Board  Players  Turn time  Match time
24     2        1:30       ~41.1 min
24     4        0:45       ~41.1 min
24     6        0:30       ~41.1 min
30     2        1:30       ~51.4 min
30     4        0:45       ~51.4 min
30     6        0:30       ~51.4 min
36     2        1:30       ~61.7 min
36     4        0:45       ~61.7 min
36     6        0:30       ~61.7 min
```
