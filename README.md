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

In the main menu pick a map: **Play · City** or **Play · Caves** (Enter replays the last map).
The game runs in a **square window**; in full screen (Cmd+F) it stays square with black bars on the sides.

### Maps

- **City:** a hand-made block of buildings, streets, alleys, crates and wrecks.
- **Caves:** a new cave system every battle, built from a noise function. Three winding tunnels run from spawn to
  spawn (the middle one passes through zones A, B and C) and narrow side passages connect them, with open chambers
  and rock pillars for cover. Every passage is at least two soldiers wide, and the generator rejects any cave where a
  zone or spawn can't be reached.

### Rules

- Two teams of **25**: you plus 24 blue bots against 25 red bots. Each team has its own spawn (blue on the left, red on the right).
- Every soldier has **100 HP**, a **primary weapon** (Assault Rifle, SMG or Shotgun, assigned randomly), a **pistol**, **one grenade** (Frag, Flashbang or Stun, random) and a **knife**. No abilities, and the shop is disabled for now.
- Every soldier gets **one respawn**: after the first death you come back at your spawn after 5 s with a fresh loadout. The second death is final.
- **Control zones:** three capture circles — **A** near the blue spawn, **B** contested in the middle, **C** near the red spawn.
  Stand in a zone with no enemies inside to capture it (~3 s for a neutral zone, longer to flip an enemy one; more
  soldiers capture faster; enemies inside contest it). A zone stays yours until the enemy takes it.
  **Each zone you hold gives your team 1 point per second.**
- **5-minute match.** When time runs out, the team with more points wins. On a tie it goes to **sudden death**:
  nobody respawns any more and the fight goes on until one team is wiped out.
- At any time, a team loses when nobody on it is alive and nobody is left to respawn. If the last soldiers of both
  teams die at the same moment, it is a **draw**.
- The map is mostly mirrored, but each half has its own wrecked cars, sandbag walls and barricades, so the two
  sides play differently.
- Walls and crates block movement, bullets, grenade blasts and line of sight.
- **View range:** nobody sees further than ~640 points; beyond that it is fog, even in front of you.
- **Range line:** a dashed line runs from your soldier along your aim to the max range of the weapon in your hand
  (rifle 1000, pistol 800, SMG 700, shotgun 430), with a gold arc at the end. Walls cut it short.
- **Field of view:** you only see a ~110° cone in front of your soldier, cut off by walls. Everything behind you and around corners is fog, apart from a small awareness ring right around you. Enemies in the fog are invisible. Bots have a similar cone (~150°), so you can flank them.
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds: your screen whites out and bots stop shooting. **Stun** slows the target and stops it from shooting.
- Bots are tuned "medium-hard": quick reactions and decent aim. They fight as **squads of ~5**:
  - they move in formation behind a squad leader, who waits for stragglers;
  - they share enemy sightings with their squad;
  - each squad weighs its numbers and health against the enemy, then **pushes**, **holds** or **falls back a bit**;
  - one squad per team defends its home zone; the others go for the middle and then the enemy zone, and go back
    to retake their home zone if it is lost;
  - two squads per team **flank**: they take a route along the top or bottom edge of the map instead of going straight through the middle;
  - **3 rogue bots per team** work alone. They circle round the edge of the battlefield and come in behind the enemy front line;
  - idle squads move in to **support** a nearby fight, and squads down to one or two soldiers **merge** into another squad;
  - in a firefight bots take **cover behind crates and walls**, peek out to shoot and duck back to reload. Wounded bots look for cover further back;
  - they notice when an enemy has its **back turned** (or is flashed or stunned). They prefer that target, leave cover and go for the kill:
    if it is close they sneak up behind it and **knife** it (a backstab is lethal), otherwise they stop and shoot it;
  - they also throw grenades, knife only at close range and strafe when there is no cover.

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
