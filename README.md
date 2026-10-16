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

**Playing without Terminal:** Terminal is only needed to *build*. Once built, open the `dist` folder and drag
**Frontline.app** into **Applications** (or onto the Dock); from then on just click it to play. Run
`Play Frontline.command` again only after you pull a new version of the game, then drag the new app over the old one.

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

In the main menu pick **Bomb (5 vs 5)** or **Rush (16 vs 16)** (Enter replays the last mode). Your side is random.
The camera follows your soldier and leans toward the mouse pointer (half-way, at most 280 points), so you can look further in the direction you aim; it is not limited by the map edges. Resizing the window or going full screen only scales the picture: you always see the same 1000×1000 area.
The game runs in a **square window**; in full screen (Cmd+F) it stays square with black bars on the sides.

### Modes

Both modes are played on **Office**, a hand-made indoor map (2400×1520) of compact rooms. It is balanced:
the floor is mirrored top/bottom, so sites A and B are exactly as far from each spawn. Attackers start in the
west lobby, with doors into the north rooms, the middle and the south rooms; defenders start in the east room, with
doors straight into both site rooms. You are put on **attack or defence at random** and are always blue.

**Bomb — 5 vs 5, one life**
- The attackers carry **one bomb** (you have it when you attack). Take it to **site A or B** and **hold E** for 3 s
  inside the site to plant it. It **explodes after 45 s**; a defender next to it can **hold E for 5 s** to defuse.
- If the carrier dies the bomb drops; any attacker can pick it up by walking over it.
- Attackers win if the bomb explodes or all defenders die. Defenders win if they defuse it, kill all attackers
  before the plant, or the **2:00** round timer runs out with no plant.

**Rush — 16 vs 16, respawns**
- Sites A and B each hold a **station**. **Any attacker** can arm either one by standing next to it and **holding E**
  for 3 s. An armed station explodes after 45 s; defenders can defuse it (5 s), and it can then be armed again.
  **Destroy both stations** to win.
- Everyone respawns after **8 s**. Every attacker respawn costs one of the attackers' **120 tickets**; when they
  run out and the last attacker falls, the defenders win.

### Rules (both modes)

- Every soldier has **100 HP**, a random **primary** (Assault Rifle, SMG or Shotgun), a **pistol**, **one grenade** (Frag, Flashbang or Stun) and a **knife**.
- Walls and desks block movement, bullets, grenade blasts and line of sight. Soldiers of different teams don't collide with each other.
- **View range** ~640 points, **field of view** ~120° for everyone; the fog follows only your own eyes and has a soft edge.
- **Range line:** a dashed line from your soldier to the max range of the weapon in hand (rifle 1000, pistol 800, SMG 700, shotgun 430).
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds. **Stun** slows and stops shooting.
- Bots ("medium-hard"):
  - **they push together**: the attackers first gather at a staging point short of their site, wait until most of
    the team is there (or time runs short), then all go in at once, opening with grenades and flashbangs. In rush
    the whole team pushes one station at a time and guards an armed one. Defenders retaking an armed bomb or
    station gather first too, then retake together, and squads from the other site come over to help;
  - the carrier plants (bomb) or the nearest free attacker arms a station (rush) when no enemy is in sight; the nearest free attacker grabs a dropped bomb;
  - defenders split over both sites; when a bomb is armed they converge on it and the nearest free defender defuses;
  - lone **rogues** (1 per team in bomb, 3 in rush) take the long way round to come in from behind;
  - they know the map's **doorways** and keep their guns on them, share and **predict** enemy positions, and **clear rooms** as a squad (stack beside the door, cover it, go in together — or sometimes just rush in);
  - they push / hold / fall back, use cover, and punish enemies with their backs turned.

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
| **E** (hold) | Plant the bomb (bomb mode, inside a site) / arm a station (rush) / defuse (defender, next to an armed bomb) |
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
