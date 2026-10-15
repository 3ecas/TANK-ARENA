# Frontline — Plan

A top-down 3-lane military MOBA for macOS, written in Swift with SpriteKit + AppKit and
built with Swift Package Manager (Xcode Command Line Tools only, no IDE or engine needed).

## Folder structure (`Sources/Frontline/`)

| Folder | Responsibility |
|---|---|
| `App/` | `@main` entry, app delegate, window + menu, `GameView` (SKView input forwarding), scene router, game scene, icon generator |
| `Core/` | Vector math, clock, input manager, key codes, event bus, camera, spatial grid, game context, game session (system order), player controller, cast input |
| `World/` | Teams, lanes, lane paths, map layout, city layout + generator, nav grid (A*), path follower, world container, steering, vision grid |
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

## Revision 2 (after first playtest)
- One customisable soldier type for everyone: pistol and no abilities at the start; everything is bought in the shop (the AI follows its own purchase order too).
- League-style controls: right-click to move or attack, Q/W/E/R abilities, F combat roll, S stop.
- City map: procedurally laid out blocks with buildings (solid) and parks between the lanes; heroes, summons and mercenaries use A* on a nav grid.

## Revision 3: close-quarters team shooter
The game was reworked from a MOBA into a top-down team shooter, as requested:
- **25 vs 25** (player + 49 bots), hand-made point-symmetric arena (2800×1800) with streets, alleys and choke points.
- Every soldier: 100 HP, a random primary (rifle / SMG / shotgun), a pistol, one random grenade (frag / flash / stun) and a knife (F).
- One respawn per soldier; a team loses when it has nobody alive and nobody left to respawn.
- WASD + mouse aim, left-click to shoot, R reload, 1/2/Q weapons, G grenade.
- Walls block movement, bullets and sight; enemies are only drawn while in the viewer's line of sight.
- Single "medium-hard" bot difficulty. The shop and the MOBA systems were removed (still in git history).

## Revision 4: control zones and time limit
- Asymmetry: `MapConfig.irregularBarriers` adds unmirrored cover (wrecked cars, sandbag walls) to each half.
- `Data/ZoneConfig` holds three zones: A (blue side), B (middle) and C (red side). `Entities/ControlZone` + `Systems/ZoneSystem` handle capture progress (-1 red … +1 blue), contesting, ownership and 1 point per second per held zone.
- `Systems/MatchSystem` runs a 5-minute timer. After it, the higher score wins; a tie starts sudden death (all respawns removed, no scoring). An elimination wins at any time; a simultaneous wipe is a draw (`MatchResult.draw`, `matchOver(winner: nil)`).
- AI: squads get a zone objective from `SquadCoordinator` (one home defender, attackers go middle → enemy, retake home if lost) and spread out inside the zone.
- Rendering/UI: `ZoneRenderer` (owner ring, capture arc, letter), zone markers on the minimap, scoreboard with points, countdown / SUDDEN DEATH and zone ownership; game-over screen shows VICTORY / DEFEAT / DRAW with the score.

## Revision 5: punishing exposed enemies
- `VisionSystem.isUnaware` tells whether an enemy is facing away from a bot (outside its view cone) or is blinded or stunned.
- Bots prefer exposed targets (`AIConfig.exposedTargetBonus`), react faster and aim better at them, and never hide from them:
  within `AIConfig.backstabRange` they sneak behind and knife; further away they stand and shoot.

## Revision 6: cave map, flanking, square window
- `World/MapLayout` describes a map (obstacles, spawns, zones). `MapKind.city` is built from `MapConfig`, and `MapKind.caves` from `World/CaveGenerator`:
  - `ValueNoise` rock, two outer tunnels plus a middle tunnel through the zones, wiggly connectors, zone clearings with pillars;
  - a flood fill over 2×2 open blocks keeps only passages at least two cells wide;
  - the result is checked with the nav grid and regenerated with a new seed if anything is unreachable.
- `CaveGrid` merges rock cells into rectangles. `ObstacleIndex` buckets obstacles, so raycasts, collisions and point tests stay fast with hundreds of rocks.
- `Rendering/CavePainter` paints floor, rock shading and rims. The main menu has Play · City / Play · Caves.
- Flanking: squad roles 2 and 3 get a `flankPoint` on the top or bottom edge before heading to the objective.
- Rogues: `AIConfig.roguesPerTeam` bots per team stay outside squads (`SoldierAIRogue`). They route along an edge to a point behind the enemy front line, then repeat.
- Square window: `WindowFactory` sets a 1:1 aspect ratio, and `SquareContainerView` keeps the game view square in full screen.
- View range limited to `GameConfig.visionRange` (640). `Rendering/RangeIndicator` draws the player's dashed aim line to the weapon's max range, plus an arc marker.
- One `GameConfig.fieldOfView` for the player and all bots. The camera is always centred on the player (no edge clamping, no free camera).
- Scenes have a fixed size (`GameConfig.viewSize`, 1000×1000) with `.aspectFit`, so the window size never changes how much of the map is visible.

## Revision 7
- New city map: irregular, unmirrored layout (`MapConfig.buildings/crates/barriers/roads`), diagonal spawns, scattered zones. Caves keep their own spawns in `CaveConfig`.
- Fog uses only the viewer's own vision (shared team vision was removed again). The visible area has a feathered edge (`GameConfig.fogFeather`), higher fog resolution and more rays.
- Camera look-ahead: the focus is player + (mouse − player) × 0.5, capped at `GameConfig.cameraLookAhead`.
