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

In the main menu pick **Attack / Defend** and **City / Caves** (Enter replays the last choice).
The camera follows your soldier and leans toward the mouse pointer (half-way, at most 280 points), so you can look further in the direction you aim; it is not limited by the map edges. Resizing the window or going full screen only scales the picture: you always see the same 1000×1000 area.
The game runs in a **square window**; in full screen (Cmd+F) it stays square with black bars on the sides.

### Rules: Breakthrough

- In the main menu pick **Attack** or **Defend**, and a map (**City** or **Caves**). You are always blue; the
  other team takes the other role. 25 vs 25 (you plus 49 bots).
- The map (4800×2400) is split into **four sectors, A → B → C → D**, each with **two control zones**
  (A1/A2 … D1/D2), far apart from each other. Only the two zones of the current sector can be captured; the
  others are faded out.
- **Attackers** must hold **both** zones of the sector at the same time. Then the sector falls, the front moves
  to the next sector and both teams' spawns move forward. Taking both zones of **sector D** wins the battle.
- Stand in a zone with no enemies inside to capture it (4 s from neutral, 8 s to flip an enemy zone; more
  soldiers capture faster; enemies inside contest it). Defenders can take zones back.
- **Respawns are unlimited, after 8 seconds.** Every attacker respawn costs one of the attackers' **200
  tickets** (+50 for each sector captured). When the tickets run out, attackers can't respawn, and the
  defenders win once the last attacker is down.
- Every soldier has **100 HP**, a random **primary** (Assault Rifle, SMG or Shotgun), a **pistol**, **one grenade** (Frag, Flashbang or Stun) and a **knife**.
- Walls, crates and rock block movement, bullets, grenade blasts and line of sight. Soldiers of different teams don't collide with each other.
- **View range:** nobody sees further than ~640 points; beyond that it is fog, even in front of you.
- **Range line:** a dashed line runs from your soldier along your aim to the max range of the weapon in your hand
  (rifle 1000, pistol 800, SMG 700, shotgun 430), with a gold arc at the end. Walls cut it short.
- **Field of view:** you and every bot see the same ~120° cone in front of you, cut off by walls. The fog only follows **your own** eyes and has a soft edge.
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds: your screen whites out and bots stop shooting. **Stun** slows the target and stops it from shooting.
- Bots are tuned "medium-hard". They fight as **squads of ~5**:
  - each team's squads split over the two active zones. Attackers go for zones they don't hold yet; defenders rush to zones being captured or lost;
  - two attacking squads **flank** along the top or bottom edge instead of going straight in, and **3 rogue bots per team** circle round to come in behind the enemy line;
  - they share enemy sightings, and **push**, **hold** or **fall back a bit** depending on numbers and health;
  - they take **cover behind crates and walls**, peek out to shoot and duck back to reload;
  - they notice enemies with their **back turned** (or flashed / stunned) and go for the kill: a knife backstab up close, shots from further away.

### Maps

- **City:** a hand-made, irregular town with roads, a few dozen buildings of different sizes, crates and wrecks.
  Sector boundaries and big sector letters are painted on the ground, and all spawn pads are marked.
- **Caves:** a new cave system every battle, built from a noise function. Two winding tunnels cross the whole map,
  a third route snakes through every zone and spawn, and narrow side passages connect them. Every passage is at least
  two soldiers wide, and a cave where a zone or spawn can't be reached is thrown away and generated again.

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
