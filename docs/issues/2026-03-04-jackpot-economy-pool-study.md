# Study Jackpot Pool Economy (2026-03-04)

Issue: `ISS-012`

## Summary
Evaluate and specify a jackpot pool mechanic where key EVA outflows are accumulated and later redistributed as rewards.

## Problem
- EVA spent on property/miner purchases and mandatory penalties currently leaves player balances without creating a visible shared reward pool.
- This can make economy flow feel purely extractive and reduces comeback/excitement moments.
- There is no formal rule yet for centralizing those payments and reusing them as winner rewards or Bull-card gifts.

## Proposed Direction
- Introduce a server-tracked `jackpot_eva` pool.
- Route these EVA payments into jackpot:
- property purchases,
- miner batch purchases,
- Bear EVA fines,
- inspection/jail fee payments.
- Define controlled outflows from jackpot, such as:
- winner prize at game end,
- selected Bull effects awarding a percentage of jackpot.

## Open Questions
- Which transactions should be jackpot-funded vs directly transferred between players?
- Should energy tolls remain peer-to-peer (payer -> owner), or partially feed jackpot?
- What percentage/rules should Bull jackpot rewards use?
- Is jackpot split only for winner, or top-N placements?
- Should jackpot contributions/payouts be visible in turn-start summary and event logs?

## Suggested Acceptance Criteria
- A written design decision in `docs/game-rules.md` and `godot2/DESIGN.md` describing:
- jackpot sources,
- jackpot sinks,
- timing and formulas.
- State-machine update identifying where jackpot is credited/debited.
- RPC/event and text-client logging requirements defined for jackpot updates.
- Follow-up implementation issue(s) created once design is approved.
