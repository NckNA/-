# Владение Prototype v0.001

## Created
- 2D Local Map (48x32 cells, 32px each).
- Terrain types: Plain, Forest, Hill, Water, Mountain.
- Resource zones: Wood (forests), Stone (hills), Iron (mountains).
- Two separate Iron resource zones with unique IDs.
- Player character with WASD movement.
- Camera with MMB panning and 'C' to center on player.
- Grid toggle with 'G'.
- Tile selection with Left Click.
- Right-side HUD showing tile info and action logs.
- Simple building system:
  - Mine (requires Iron).
  - Lumber Camp (requires Forest/Wood).
  - Quarry (requires Stone).
- Building rules: No building on occupied tiles, buildings inherit resource zone IDs.
- Deterministic map generation.

## Controls
- **WASD**: Move player.
- **MMB (Middle Mouse Button)**: Pan camera.
- **C**: Center camera on player.
- **G**: Toggle grid visibility.
- **Left Click**: Select a tile.
- **UI Buttons**: Build structures on selected tiles.

## How to run in Godot
1. Open Godot 4.x.
2. Import the project by selecting `project.godot` in the root directory.
3. Press F5 (or the Play button) to run the `Main.tscn` scene.

## Current Limitations
- No actual economy (resources are not gathered over time).
- Visuals are basic ColorRects and shapes (no sprites).
- No saving or loading.
- One single local map.

## Next Version Ideas (v0.002)
- Resource accumulation over time from buildings.
- Better visual representation (simple sprites or more detailed _draw shapes).
- Basic resource display in HUD.
- Sound effects for building and selection.
