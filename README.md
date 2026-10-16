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

In the main menu pick **Attack / Defend** and **Compound / Office / Caves** (Enter replays the last choice).
The camera follows your soldier and leans toward the mouse pointer (half-way, at most 280 points), so you can look further in the direction you aim; it is not limited by the map edges. Resizing the window or going full screen only scales the picture: you always see the same 1000×1000 area.
The game runs in a **square window**; in full screen (Cmd+F) it stays square with black bars on the sides.

### Rules: bomb defusal (5 vs 5)

- In the main menu pick **Attack** or **Defend** and a map (**Compound**, **Office** or **Caves**). You are always blue,
  with 4 bot teammates against 5 bots.
- **One life per round**, no respawns.
- The attackers carry **one bomb** (you have it when attacking). Take it to **site A or B** and **hold E** inside
  the site for 3 s to plant it. Planting or defusing roots you in place.
- Once planted, the bomb **explodes after 45 seconds** and the attackers win (the blast kills anyone close).
  A defender standing next to it can **hold E for 5 s to defuse** it.
- If the bomb carrier dies, the bomb drops on the floor; any attacker can walk over it to pick it up.
- **Attackers win** if the bomb explodes or all defenders are dead.
  **Defenders win** if they defuse the bomb, kill all attackers before the plant, or the **2:00 round timer**
  runs out before a plant. After the plant the timer stops: the defenders must defuse.
- Every soldier has **100 HP**, a random **primary** (Assault Rifle, SMG or Shotgun), a **pistol**, **one grenade** (Frag, Flashbang or Stun) and a **knife**.
- Walls, crates and rock block movement, bullets, grenade blasts and line of sight. Soldiers of different teams don't collide with each other.
- **View range** ~640 points, **field of view** ~120° for everyone; the fog follows only your own eyes and has a soft edge.
- **Range line:** a dashed line from your soldier to the max range of the weapon in hand (rifle 1000, pistol 800, SMG 700, shotgun 430).
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds. **Stun** slows and stops shooting.
- Bots ("medium-hard"):
  - the attackers move as one squad to a site picked at random each round, the carrier plants as soon as it is inside the site with no enemy in sight, and the nearest attacker picks up a dropped bomb;
  - the defenders split into pairs guarding A and B; after a plant everyone converges on the bomb and the nearest defender defuses when no enemy is in sight;
  - one lone **rogue** per team takes the long way round to come in from behind;
  - they know the map's **doorways and entrances** (found automatically on every map) and keep their guns on them:
    holding bots watch the openings facing the enemy side, switching every few seconds, and walking bots check
    doorways as they pass;
  - every sighting is **shared with the team** and extrapolated from the enemy's movement, so bots aim where an
    enemy should be now, or at the doorway it would come through;
  - squads **clear rooms**: they stack up beside the next doorway on their path, wait for everyone, cover the
    opening, then go in together. Sometimes they just push straight in — always when the bomb is ticking or the
    attackers are short of time;
  - they share sightings, push / hold / fall back, use cover, and punish enemies with their backs turned.

### Maps

- **Compound:** a closed indoor map (2400×1600) of rooms, corridors and doorways. Attackers start in the west room,
  defenders in the east room between the sites. Three routes: the long north corridor to A, the mid hall with short
  connectors to A and B, and the south tunnels to B.
- **Office:** an irregular floor generated new every round, nothing mirrored. The floor is split again and
  again by walls at random positions into rooms of every size, each wall with one or two doorways (so every room
  is reachable), with desks as cover. The two bomb sites are placed at random each round, far apart: A in the
  upper right, B in the lower middle.
- **Caves:** a new cave system every round, built from a noise function, with the same spawns and sites; every
  passage is at least two soldiers wide and unreachable layouts are regenerated.

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
| **E** (hold) | Plant the bomb (attacker carrying it, inside a site) / defuse it (defender, next to it) |
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
