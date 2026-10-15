# Frontline

A top-down 2D **close-quarters team shooter** for macOS (think Counter-Strike seen from above).
**Blue vs red, 25 soldiers each**: you plus 49 AI bots, mass firefights through alleys, streets and choke points.

Native macOS app: **Swift + SpriteKit + AppKit**, built with Swift Package Manager.
No game engine, no browser, no third-party dependencies. All graphics and sounds are generated in code.

## Requirements

- macOS 13 (Ventura) or newer, Apple Silicon or Intel
- **Xcode Command Line Tools** (the full Xcode IDE is *not* needed):

  ```bash
  xcode-select -p          # prints a path if they are installed
  xcode-select --install   # installs them if they are missing
  ```

  `scripts/build_app.sh` checks for them and stops with instructions if they are missing.

## Build and play (easiest)

Double-click **`Play Frontline.command`** in Finder. It opens Terminal, builds the game and launches the
game window. The first build takes a minute or two; after that the game is in `dist/Frontline.app`, which you can
double-click directly (or drag into Applications).

> Don't double-click `scripts/build_app.sh`: Finder opens `.sh` files in a text editor instead of running them.
> If macOS blocks the `.command` file the first time, right-click it → **Open**.

## Build from Terminal

```bash
./scripts/build_app.sh
open dist/Frontline.app
```

This builds in release mode and produces **`dist/Frontline.app`**, a normal app bundle
(`Contents/MacOS`, `Contents/Info.plist`, `Contents/Resources/AppIcon.icns`). The icon is drawn by the game itself.
The bundle is ad-hoc code-signed, so it opens on Apple Silicon.

For development you can also run `swift build` and then `swift run Frontline`.

## Play

Double-click `dist/Frontline.app`, or drag it into `/Applications`.
(If you copy the app to another Mac, the first launch may need right-click → **Open**, because the app is ad-hoc signed.)

Press **Play** in the main menu.

### Rules

- Two teams of **25**: you plus 24 blue bots against 25 red bots. Each team has its own spawn (blue on the left, red on the right).
- Every soldier has **100 HP**, a **primary weapon** (Assault Rifle, SMG or Shotgun, assigned randomly), a **pistol**, **one grenade** (Frag, Flashbang or Stun, random) and a **knife**. No abilities, and the shop is disabled for now.
- Every soldier gets **one respawn**: after the first death you come back at your spawn after 5 s with a fresh loadout. The second death is final.
- A team loses when nobody on it is alive and nobody is left to respawn. The other team wins.
- Walls and crates block movement, bullets, grenade blasts and line of sight. You only see enemies your soldier has a clear line of sight to.
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds: your screen whites out and bots stop shooting. **Stun** slows the target and stops it from shooting.
- Bots are tuned "medium-hard": quick reactions and decent aim. They strafe, reload, throw grenades, knife up close and hunt you after losing sight of you.

### Controls

| Input | Action |
|---|---|
| **W A S D** (or arrows) | Move |
| **Mouse** | Aim (your soldier faces the cursor) |
| **Left mouse** | Shoot (hold for the rifle and SMG; click per shot for the pistol and shotgun) |
| **R** | Reload (also automatic when the magazine is empty) |
| **1 / 2 / Q** | Primary / pistol / swap |
| **G** | Throw your grenade at the cursor |
| **F** | Knife (hitting someone from behind is an instant kill) |
| **Tab** (hold) | Scoreboard |
| **Space** | Re-centre the camera |
| **Esc** | Pause menu |
| **Cmd+F** / green button | Toggle full screen |
| **F1** | Toggle FPS counter |

## Project layout

See [`PLAN.md`](PLAN.md) for the architecture. The short version:

```
Sources/Frontline/
  App/        entry point, window, menus, input view, scene router, game scene, icon
  Core/       math, clock, input, event bus, camera, session (system order), battle setup, player controls
  World/      teams, arena map (walls, raycasts), nav grid (A*), path follower, battle world
  Entities/   soldier, weapon state, grenade
  Systems/    movement, weapons, ballistics, damage, knife, grenades, status, respawns, vision, match end
  AI/         bot brain (advance along routes, fight, hunt, grenades, knife)
  UI/         HUD (health, weapons, team counts, kill feed, crosshair, flash), minimap, scoreboard, menus
  Rendering/  code-drawn textures, arena map, soldier views, effects
  Audio/      procedurally synthesised sound effects
  Data/       every tuning number (weapons, grenades, AI, map layout, rules)
```

All balance numbers live in `Data/`, so tuning never needs changes in game logic.
