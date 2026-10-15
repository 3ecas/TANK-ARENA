# Frontline

A top-down, 3-lane **modern-warfare MOBA** for macOS. You are a soldier hero fighting next to AI troops.
Buy abilities in the armory, call in airstrikes, tanks and reinforcements, and destroy the enemy HQ.

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

In the main menu, pick a **difficulty** (Easy / Normal / Hard) and a **starting loadout** (Assault, Support or Commander),
then press **Play**.

### Controls

| Input | Action |
|---|---|
| **W A S D** (or arrows) | Move |
| **Mouse** | Aim (the soldier faces the cursor) |
| **Right mouse** | Click on or near an enemy to lock it and auto-fire. Hold to keep firing at the enemy nearest the cursor. Click empty ground to clear |
| **Left mouse** | Ability slot 1 |
| **Q / E / R** | Ability slots 2, 3, 4 |
| Hold + release | Area / targeted abilities show a reticle while held and cast on release. **Esc** while holding cancels |
| **1 2 3 4** | Spend an ability point to rank up the ability in that slot |
| **B** | Recall to base (5 s channel, interrupted by damage or moving) |
| **P** | Open the armory (only at base) |
| **Tab** (hold) | Scoreboard |
| **Space** | Center the camera on your soldier |
| **Esc** | Pause menu |
| **Cmd+F** / green button | Toggle full screen |
| Click the minimap | Move the camera there (Space snaps back) |
| **F1** | Toggle FPS / node counter |

Right-click never opens a context menu. Ctrl+click also counts as a right click.

### How the game works

- **Map:** blue base bottom-left, red base top-right. There are three lanes (top, mid, bot), a river from corner to corner and neutral zones between the lanes. You only see what your units and structures see (fog of war).
- **Teams:** 5 v 5 heroes: you plus 4 AI allies against 5 AI enemies.
- **Waves:** every 30 s each HQ sends riflemen and rocket soldiers down every lane. Later waves include tanks and APCs (an APC drops riflemen when destroyed).
- **Structures:** each lane has 2 bunkers and a barracks per team, and each base has an HQ. Inner bunkers, barracks and the HQ are invulnerable (grey HP bar) until the structures in front of them fall. Bunkers shoot troops first, but switch to any hero who attacks an allied hero in their range. Destroying an enemy barracks makes your waves in that lane stronger. **Destroy the enemy HQ to win.**
- **Progression:** you earn gold from last hits, kills, assists, objectives and passive income, and XP up to level 18. Each level gives an ability point. The respawn timer grows with your level.
- **Armory (P at base):**
  - **Abilities:** 16 abilities in 4 categories (Combat, Support, Call-ins, Summons). Buy one to unlock it, buy it again to rank it up (max rank 3). Equip abilities into the 4 slots (LMB / Q / E / R) in the loadout strip; equipping only works at base.
  - **Weapons:** Assault Rifle, Combat Shotgun, Sniper Rifle and Light Machine Gun, each with different range, fire rate, damage and magazine size. Reloading is automatic.
  - **Gear:** 6 slots. There are 6 basic items, and each one upgrades into an advanced item (for example Kevlar Vest → Ceramic Plates).
- **Command Points (CP):** earned from kills (2), assists (1), objectives and slowly over time. Ultimate abilities (Carpet Bombing, Call in Tank, Attack Helicopter) cost CP on top of their cooldown.
- **Summons** have caps and lifetimes: 1 tank (pushes the nearest lane), 2 squads (follow you, then join a lane), 1 helicopter (escorts you) and 2 sentry turrets.
- **Call-ins** always show a telegraphed warning zone before impact, so you (and the AI) can dodge them.
- **Objectives:**
  - **Mercenary camps** (4) give gold and XP.
  - **Radar Station** (capture point, top river): gives your team extra vision.
  - **Airfield** (capture point, bottom river): your call-in cooldowns are 25% shorter.
  - **Heavy Armor Depot** (from 8:00): a guardian boss. The team that kills it gets a **Super Tank** that pushes mid.
- **AI heroes** use a state machine (laning/farming, trading, retreating, recalling to shop, ganking, objectives, pushing/defending). Each one follows its own build, uses abilities with cooldown gaps, aims call-ins at clustered enemies, dodges telegraphed strikes and respects bunker range. Difficulty changes reaction time, aim error, dodge chance, ability use, aggression and enemy gold income.

## Project layout

See [`PLAN.md`](PLAN.md) for the architecture. The short version:

```
Sources/Frontline/
  App/        entry point, window, menus, input view, scene router, game scene, icon
  Core/       math, clock, input, event bus, camera, spatial grid, session (system order), player control
  World/      teams, lanes, map layout, world state, steering, vision grid
  Entities/   entity classes, projectiles, strike zones, area zones, capture points, factory
  Systems/    movement, collision, targeting, combat, damage, health, economy, XP, CP, waves, objectives, vision...
  Abilities/  ability protocol, registry, cast system, loadout, one file per ability
  Summons/    summon controller + summon AI hand-off
  Shop/       armory logic (abilities, weapons, gear)
  AI/         unit brains and the hero AI state machine
  UI/         HUD, ability bar, minimap, shop, scoreboard, menus, targeting overlay
  Rendering/  code-drawn textures, map, entity views, effects, fog
  Audio/      procedurally synthesised sound effects
  Data/       every tuning number (stats, costs, cooldowns, waves, AI difficulty, builds)
```

All balance numbers live in `Data/`, so tuning never needs changes in game logic.
