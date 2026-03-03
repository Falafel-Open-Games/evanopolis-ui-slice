# Incident Cards

Reference:
- Canonical rules: `docs/game-rules.md`

## v0 Baseline (Implement First)

These are the only incident effects required for v0 full-game validation.
All are immediate effects (no delayed or multi-turn state).

### Bear (self-impact)
1. `bear_fine_eva_2`: current player pays `2 EVA`.
2. `bear_lost_btc_0_5`: current player loses `0.5 BTC`.
3. `bear_legal_inspection`: current player is sent to inspection.

### Bull (self-impact)
1. `bull_gain_eva_2`: current player gains `2 EVA`.
2. `bull_gain_btc_0_2`: current player gains `0.2 BTC`.
3. `bull_free_inspection_exit`: current player gains `1` free inspection exit.

## Post-v0 Backlog

These ideas are valid, but deferred until after v0.

### Deferred Bear ideas
- `bear_equipment_failure`: lose 1 miner batch on a property.
- `bear_tax_audit_percent`: pay 10% of fiat balance.
- `bear_cooling_leak_choice`: pay fiat or remove 1 miner batch.
- `bear_network_congestion_cycle`: payouts from properties halved this cycle.
- `bear_emergency_shutdown_cycle`: one property produces no BTC this cycle.
- `bear_forced_sale`: sell one property for 50% fiat price.
- `bear_customs_delay`: skip next turn. *(Not for v0)*

### Deferred Bull ideas
- `bull_energy_discount_cycle`: pay no energy tolls this cycle.
- `bull_hardware_windfall_discount`: gain 1 miner batch at discount.
- `bull_hosting_demand_collect_all`: collect fiat from each other player. *(Not for v0)*
- `bull_bulk_import_discount`: next miner batch has reduced fiat cost.
- `bull_local_grant`: gain fixed fiat amount.
- `bull_hashrate_upgrade_cycle`: one property gains temporary miner capacity.
- `bull_logistics_win_instant`: place 1 miner batch instantly.
- `bull_whale_buyer_trade`: sell 1 BTC for fixed fiat.
- `bull_market_hype_btc`: gain +0.5 BTC.
- `bull_gain_miner_1`: current player gains 1 miner batch. *(Not for v0)*
