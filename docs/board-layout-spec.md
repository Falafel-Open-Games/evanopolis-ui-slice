# Board Layout Spec (Hex Ring, Fixed A-B-C Template)

## Goals

- Support 24/30/36 tile boards with a single layout rule.
- Keep class counts fixed: A=6, B=6, C=variable.
- Use full city clusters (no splitting).
- Avoid hardcoded strips or per-size special cases.

## Tile Classes

- Class A (6 total): Start, Jail, 4x Incident.
- Class B (6 total): Special properties (one per side).
- Class C (variable): City properties (6 cities * properties per city).

## Board Size Formula

- `total_tiles = 12 + 6 * properties_per_city`
- `tiles_per_side = total_tiles / 6`
- Supported: 24 (2 per city), 30 (3 per city), 36 (4 per city)

## Indexing Convention

- Tile indices are 0..(total_tiles-1).
- Sides are 0..5, ordered clockwise.
- Side 0 is the corner that contains Start.
- Each side is laid out left-to-right in ring order.
- Side `s` spans indices: `s * tiles_per_side` .. `s * tiles_per_side + (tiles_per_side - 1)`.

## Per-Side Template (Fixed)

- Slot 0: A
- Slot 1: B
- Slots 2..(tiles_per_side-1): C
- This is repeated identically for all 6 sides.

## A/B Assignment Order

- A per side (fixed order by side):
  - Side 0: Start
  - Side 1: Incident 1
  - Side 2: Incident 2
  - Side 3: Jail
  - Side 4: Incident 3
  - Side 5: Incident 4
- B per side: Special Property 1..6 in side order (0..5).

## City Cluster Rule

- Cities are assigned to Class C slots as full clusters.
- City 1..6 fill C slots in ring order, sequentially.
- Each city gets exactly `properties_per_city` consecutive C slots.

## Slot Tables

### 24 Tiles (2 properties per city)

- `tiles_per_side = 4`
- Per side: `A B C C`

Side 0: 0 A, 1 B, 2 C, 3 C  
Side 1: 4 A, 5 B, 6 C, 7 C  
Side 2: 8 A, 9 B, 10 C, 11 C  
Side 3: 12 A, 13 B, 14 C, 15 C  
Side 4: 16 A, 17 B, 18 C, 19 C  
Side 5: 20 A, 21 B, 22 C, 23 C

City clusters (C slots):

- City 1: 2, 3
- City 2: 6, 7
- City 3: 10, 11
- City 4: 14, 15
- City 5: 18, 19
- City 6: 22, 23

### 30 Tiles (3 properties per city)

- `tiles_per_side = 5`
- Per side: `A B C C C`

Side 0: 0 A, 1 B, 2 C, 3 C, 4 C  
Side 1: 5 A, 6 B, 7 C, 8 C, 9 C  
Side 2: 10 A, 11 B, 12 C, 13 C, 14 C  
Side 3: 15 A, 16 B, 17 C, 18 C, 19 C  
Side 4: 20 A, 21 B, 22 C, 23 C, 24 C  
Side 5: 25 A, 26 B, 27 C, 28 C, 29 C

City clusters (C slots):

- City 1: 2, 3, 4
- City 2: 7, 8, 9
- City 3: 12, 13, 14
- City 4: 17, 18, 19
- City 5: 22, 23, 24
- City 6: 27, 28, 29

### 36 Tiles (4 properties per city)

- `tiles_per_side = 6`
- Per side: `A B C C C C`

Side 0: 0 A, 1 B, 2 C, 3 C, 4 C, 5 C  
Side 1: 6 A, 7 B, 8 C, 9 C, 10 C, 11 C  
Side 2: 12 A, 13 B, 14 C, 15 C, 16 C, 17 C  
Side 3: 18 A, 19 B, 20 C, 21 C, 22 C, 23 C  
Side 4: 24 A, 25 B, 26 C, 27 C, 28 C, 29 C  
Side 5: 30 A, 31 B, 32 C, 33 C, 34 C, 35 C

City clusters (C slots):

- City 1: 2, 3, 4, 5
- City 2: 8, 9, 10, 11
- City 3: 14, 15, 16, 17
- City 4: 20, 21, 22, 23
- City 5: 26, 27, 28, 29
- City 6: 32, 33, 34, 35
