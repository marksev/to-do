# Block Blast — Godot 4 Clone

A polished Block Blast clone built in Godot 4 (GDScript).

## How to Play

- Drag pieces from the bottom tray onto the 8×8 grid
- Complete full rows or columns to clear them and score points
- Clear multiple lines at once for combo multipliers
- Game ends when no piece can fit anywhere on the board

## Setup & Running

### Prerequisites
- Godot 4.x (tested on 4.2+)

### Run in Editor
```bash
godot --path godot_blockblast --editor
```

### Run Directly
```bash
godot --path godot_blockblast
```

Or open `godot_blockblast/` as a project in the Godot editor and press **F5**.

## Project Structure

```
godot_blockblast/
├── project.godot          # Project config, main scene = scenes/Main.tscn
├── icon.svg
├── scenes/
│   ├── Main.tscn          # Root scene — wires everything together
│   ├── Board.tscn         # 8×8 grid rendering + logic
│   ├── Piece.tscn         # Draggable piece (instantiated at runtime)
│   ├── Cell.tscn          # Individual grid cell (unused directly)
│   ├── UI.tscn            # Score display, combo popup, game-over overlay
│   └── ParticleExplosion.tscn  # GPU particle burst on line clear
├── scripts/
│   ├── Main.gd            # Game coordinator: tray management, drag routing
│   ├── Board.gd           # Grid state, placement, line-clear, ghost preview
│   ├── Piece.gd           # Drag-and-drop piece with visual cell building
│   ├── Cell.gd            # Simple cell helper
│   ├── PieceData.gd       # 20 unique piece shape definitions + colors
│   ├── ScoreManager.gd    # Score, high score, combo, file save/load
│   ├── SoundManager.gd    # Procedural audio via AudioStreamWAV generation
│   └── UI.gd              # Animated score counter, combo popup, game-over
└── assets/
    ├── fonts/             # (add custom fonts here if desired)
    └── sounds/            # (add OGG files here to replace procedural audio)
```

## Scoring

| Action | Points |
|--------|--------|
| Place 1 cell | 10 pts |
| Clear 1 line | 100 pts × combo |
| Clear 2 lines | 200 pts × combo |
| Combo multiplier | Increases by 1 per clear event |

High score is saved automatically to `user://highscore.save`.

## Features

- 20 unique piece shapes (I, L, J, T, S, Z, square, plus, corners, dots, etc.)
- Smooth drag-and-drop with green/red ghost preview
- Simultaneous row + column clearing (Block Blast style)
- Combo system with animated popup text
- Animated score counter
- Cell flash + particle burst on line clear
- Procedural audio (place thud, clear sweep, combo chime, game-over chord)
- Ambient background music loop (generated via AudioStreamWAV)
- High score persistence
- Restart without re-launching
