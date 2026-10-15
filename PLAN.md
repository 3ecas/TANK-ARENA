# Frontline — Plan

A top-down 3-lane military MOBA for macOS, written in Swift with SpriteKit + AppKit and
built with Swift Package Manager (Xcode Command Line Tools only, no IDE or engine needed).

## Folder structure (`Sources/Frontline/`)

| Folder | Responsibility |
|---|---|
| `App/` | `@main` entry, app delegate, window + menu, `GameView` (SKView input forwarding), scene router, game scene, icon generator |
| `Core/` | Vector math, clock, input manager, key codes, event bus, camera, spatial grid, game context, game session (system order), player controller, cast input |
| `World/` | Teams, lanes, lane paths, map layout, world container, steering, vision grid |
| `Entities/` | Entity base + Hero, Infantry, Vehicle, Aircraft, Turret, Structure; projectiles, strike zones, area zones, capture points, status effects, factory |
| `Systems/` | Movement, collision, targeting, combat, hero auto-attack, projectiles, damage, health, status, death/respawn, strikes, zones, waves, economy, XP, command points, recall, structures, objectives, neutral camps, vision, win condition, stat calculation |
| `Abilities/` | `Ability` protocol, registry, ability system (cast/cooldowns), loadout + loadout manager, one file per ability (16) |
| `Summons/` | Summon controller (caps, lifetimes, spawning) and the summon brain with lane hand-off |
| `Shop/` | Shop service, ability/weapon/gear purchasing |
| `AI/` | Unit brains (lane troops, structures, camps, guards), hero AI controller + one file per state, perception, ability usage, shopping, dodging |
| `UI/` | Buttons/styles, HUD pieces, ability bar, minimap, shop panel, scoreboard, pause/game-over overlays, targeting overlay, main menu |
| `Rendering/` | Textures drawn in code (CoreGraphics → SKTexture, cached), map texture, entity views, projectile/effect/strike/zone/fog renderers |
| `Audio/` | Procedurally synthesised sound effects (AVAudioEngine) |
| `Data/` | All tuning numbers: units, heroes, weapons, gear, abilities, waves, economy, objectives, AI difficulty and builds |

## Main architecture rules
- **Logic and rendering are separate.** Entities are plain logic objects; `Rendering/` diffs the world each frame and keeps SpriteKit nodes in sync.
- **Systems own behaviour.** Entities do not call each other; systems mutate them and publish `GameEvent`s on the `EventBus` (damage, kills, shots, explosions, gold, level-ups...). UI, audio and effects subscribe to events.
- **Controllers write intent** (move direction, aim point, target id, ability requests). The player controller reads input; hero AI writes the same fields.
- **All numbers live in `Data/`.**
- Spatial grid for neighbour queries, texture cache for all sprites, pooled/hand-animated effect nodes (no per-shot closures).

## Update order (per frame, `GameSession.update`)
player controller → hero AI → unit brains → abilities/cooldowns → status effects → movement → collision →
hero auto-attack → unit combat → projectiles → strikes → zones → health/regen → recall → summons → waves →
neutral camps → objectives → structures → economy → vision → death/cleanup → win condition.

## Milestones
1. **M1** window, map, camera, WASD, mouse aim, right-click auto-attack with target lock, auto-reload, build script
2. **M2** lanes, troop waves, bunkers, barracks, HQ, win condition
3. **M3** gold / XP / levels, 4-slot ability system, first abilities (grenade, roll, medkit, airstrike)
4. **M4** shop (abilities, weapons, gear) and loadout swapping at base
5. **M5** summons (tank, squads, helicopter, sentry) and command points
6. **M6** hero AI for allies and enemies (state machine, builds, dodging, difficulty)
7. **M7** objectives (camps, radar, airfield, armor depot), fog of war, minimap, polish (effects, sounds, menus)
