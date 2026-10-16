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

Bomb mode is played on **Office**, a hand-made indoor map (2400×1520) of compact rooms. It is balanced:
the floor is mirrored top/bottom, so sites A and B are exactly as far from each spawn. Attackers start in the
west lobby, with doors into the north rooms, the middle and the south rooms; defenders start in the east room, with
doors straight into both site rooms. You are put on **attack or defence at random** and are always blue.

**Bomb — 5 vs 5, one life**
- The attackers carry **one bomb** (you have it when you attack). Take it to **site A or B** and **hold E** for 3 s
  inside the site to plant it. It **explodes after 45 s**; a defender next to it can **hold E for 5 s** to defuse.
- If the carrier dies the bomb drops; any attacker can pick it up by walking over it.
- Attackers win if the bomb explodes or all defenders die. Defenders win if they defuse it, kill all attackers
  before the plant, or the **2:00** round timer runs out with no plant.

**Rush — 16 vs 16, respawns, 5 sectors** (its own long map, 8000×2000)
- The attackers fight through **five sectors** from west to east. Each sector has **two stations** (sector 5 has
  one). **Any attacker** can arm a station by standing next to it and **holding E** for 3 s; it explodes after 45 s
  unless a defender defuses it (5 s), and a defused station can be armed again. When **every station of a sector**
  is destroyed, the front moves to the **next sector**: both teams' spawns move forward and the attackers get
  40 tickets back. Destroy the last station in sector 5 to win.
- Sectors **1–2** are a close-quarters office building; sectors **3–5** are open ground with scattered buildings
  and cover, where **vehicles** can be used.
- Everyone respawns after **8 s**. Every attacker respawn costs one of the attackers' **120 tickets**; when they
  run out and the last attacker falls, the defenders win.
- **Downed and revived:** in rush a soldier who drops is **downed** for 10 s first. A **medic** holding **E** next
  to them for 1.6 s revives them at 50 HP; otherwise they bleed out and respawn.
- **Killstreak vehicles** (sectors 3–5): **3 kills in a row** without dying earn a **tank**, **5** a
  **helicopter**. Press **Q** to call it in — you drive it (WASD drive, mouse aims the gun, left mouse fires).
  At most **2 tanks and 1 helicopter per team** at a time. Tanks are tough and fire explosive shells;
  helicopters fly over walls with a minigun and leave after 60 s. Bullets barely scratch vehicles — use **RPGs**.

### Classes

Pick a class in the main menu (bots get a mix). Everyone has a primary (Assault Rifle or SMG), a pistol and a knife.
- **Assault:** 50% more ammo, 10% faster, **2 grenades**. Q: **adrenaline** (a short sprint).
- **Medic:** Q: drops a **health box** that heals teammates around it. Holds **E** on downed teammates to **revive** them.
- **Engineer:** carries an **RPG** (slot **3**) that wrecks vehicles and blows up infantry. Q: drops an **ammo box**
  that refills teammates' ammo and grenades.
Class abilities have an 18 s cooldown. In rush sectors 3–5 an earned vehicle takes over Q until it is called in.

### Rules (both modes)

- Every soldier has **100 HP**, a random **primary** (Assault Rifle or SMG), a **pistol**, grenades (Frag, Flashbang or Stun), a **knife** and their class gear.
- Walls and desks block movement, bullets, grenade blasts and line of sight. Soldiers of different teams don't collide with each other.
- **View range** ~640 points, **field of view** ~120° for everyone; the fog follows only your own eyes and has a soft edge.
- **Range line:** a dashed line from your soldier to the max range of the weapon in hand (rifle 1000, pistol 800, SMG 700, RPG 950).
- Grenades: **Frag** damages (falls off with distance). **Flashbang** blinds. **Stun** slows and stops shooting.
- Bots ("medium-hard"):
  - **they push together**: the attackers first gather at a staging point short of their site, wait until most of
    the team is there (or time runs short), then all go in at once, opening with grenades and flashbangs. In rush
    the whole team pushes one station at a time and guards an armed one. Defenders retaking an armed bomb or
    station gather first too, then retake together, and squads from the other site come over to help;
  - the carrier plants (bomb) or the nearest free attacker arms a station (rush) when no enemy is in sight; the nearest free attacker grabs a dropped bomb;
  - they **shoot the objective player first** (whoever carries, plants, arms or defuses a bomb);
  - defenders **hold the entrances** of their site room instead of standing on the site, and the nearest free
    defender runs to a station the moment an attacker starts arming it;
  - in rush the attackers go for the station where they have seen the fewest defenders, and when a push runs out
    of people they **regroup with the respawned players and go again as a wave**;
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
| **1 / 2 / 3** | Primary / pistol / RPG (engineer) |
| **Q** | Class ability, or call in an earned vehicle (rush sectors 3–5) |
| **G** | Throw your grenade at the cursor |
| **F** | Knife (hitting someone from behind is an instant kill) |
| **E** (hold) | Plant the bomb / arm a station / defuse / revive a downed teammate (medic) |
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
