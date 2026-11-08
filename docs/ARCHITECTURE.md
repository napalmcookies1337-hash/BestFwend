# Architecture

The Buddy's physics, the tools, the economy and the UI must grow without knowing each other's internals. They talk through `Events`, read shared state from `Game`, and describe content with data.

## Folder structure

```
data/tools/        One ToolDef .tres per tool. Adding one adds it to the toolbar.
scenes/            main.tscn (the sandbox).
scripts/main.gd    The sandbox: room, world, HUD; slow-mo, gravity, clean up, shortcuts.
scripts/core/      Services with no UI or physics: Events, Game, Profile, SaveStore, etc.
scripts/data/      Resource classes and catalogs (ToolDef, ToolCatalog).
scripts/tools/     ToolUser (input for tools), ToolBehavior, and behaviors/ (one script per kind of tool).
scripts/world/     Things in the physics world: Room, Grabber (the Hand), WorldObject, Blood, DecalLayer, Fx, Layers.
scripts/world/placed/  Landmine, StickyDynamite, PinNail, BlackHole.
scripts/world/buddy/  The Buddy: body and motor, parts, and its drawing.
scripts/ui/        HUD, panels, theme and icon art.
tests/             Automated tests and the screenshot tool. Excluded from builds.
docs/              This document.
DESIGN.md          The approved design. Change only with the creative director.
```

Dependencies point one way: `ui` and `world` may use `core` and `data`; `core` uses neither. The HUD never touches the world: it emits its own signals (`respawn_pressed`, `gravity_chosen`, ...) and `main.gd` acts on them.

## Autoloads

| Autoload | Job |
|---|---|
| `Events` | Global signal bus. Holds no state. |
| `Game` | The player's `Profile` and its save file: load at start, autosave every 30 s when something changed, save on quit. The only place $$$ is earned or spent. Applies settings to audio and the window. |
| `Sfx` | Synthesized sounds and the player pool. |

Don't add an autoload for a feature. New systems (economy, achievements) become plain objects owned by `Game` or the sandbox, so tests can build them on their own.

## Events

Declared in [events.gd](../scripts/core/events.gd), many ahead of the milestone that first emits them.

- Use `Events` when the emitter shouldn't know who listens: "the Buddy was hit", "$$$ was earned". Achievements, rewards and stats listen here.
- **Connect inline functions with `Events.listen(self, Events.some_signal, func ...)`**, never `Events.some_signal.connect(func ...)`. Godot doesn't drop a lambda's connection when the node that made it is freed, so it would keep running after a respawn. Connecting a method (`Events.x.connect(_on_x)`) is fine either way. A test guards this.
- Use a local signal when only the owner cares, as the HUD does with `main.gd`.
- Call a method when you need a result or own the target: `Game.spend(...)`, `room.clear_decals()`.
- Name signals in the past tense. Give them typed parameters.
- Listeners must not assume an order among themselves.

`buddy_hit` carries a Dictionary (`part`, `force`, `source`, `damage`, `position`) so new hit types don't need new signals.

## Money

`Game.earn(amount, reason)` and `Game.spend(amount, reason) -> bool`. Both emit events and mark the save dirty. Amounts are ints; `Fmt.money` shows them as `$$$ 1,234`.

- **What pays** is [economy.gd](../scripts/core/economy.gd): plain rules, testable on their own. A hit is worth `damage x 1.6` plus a little for force. Each different tool used in the last 10 s adds +0.25 to the combo (max x2.5). Repeating one tool tires it (x0.88 per use, down to x0.25), recovering 1 level per second; hits within 0.4 s count as one use, so a slam that hits five parts isn't penalised. Limb lost, knockout and shatter pay bonuses. Gentle actions (poke, tickle) pay a little.
- **Who gets credit:** `Economy.tool_for(info)` maps a hit to a tool: wall slams are the Hand, explosions carry their `tool`, object kinds map to tools.
- [rewards.gd](../scripts/world/rewards.gd) listens for hits and bonuses, pays through `Game.earn`, merges hits close together into one floating `+$$$` popup, and emits `Events.combo_changed` for the HUD.
- `Game.reward_multiplier()` scales every payout (prestige in Milestone 7).
- `tests/probe_economy.gd` prints $$$ per minute under different play styles; `test_economy_pacing` keeps it in range.

## Shop and ownership

- `Game.tool_status(id)`: owned, locked (its `requires` tool isn't owned), too_expensive, or buyable. `Game.buy_tool(id)` and `Game.upgrade_tool(id)` spend, save, and emit `tool_purchased` (the HUD then selects a new tool and plays a cha-ching).
- Upgrades: 3 levels, each +25% power. `ToolBehavior.power()` applies them: force, damage, durations, telekinesis reach, and explosion push/damage (radius grows with the square root). Explosive objects carry `power_scale`. The Hand's upgrade ("Strong Arm") throws harder.
- `Game.TOOLS_FREE` (now false) would make every tool usable without buying.
- The toolbar shows unowned tools dimmed with a lock and price; clicking one opens the shop on its tab. The HUD announces each newly affordable tool once per session and marks the Shop button "(!)".

## Tools

A tool is a `ToolDef` resource in `data/tools/`: name, description, category, toolbar order, price, targeting, `use_interval`, `duration`, `strength`, a `behavior` script and a `params` dictionary. `ToolCatalog` finds every file there, so adding a tool needs no registration. Tools are unlimited: `use_interval` only rate-limits held tools like the pistol, never a cooldown. `Game.TOOLS_FREE` makes every tool usable until the shop exists; Milestone 5 turns it off.

- **Input:** [tool_user.gd](../scripts/tools/tool_user.gd) takes left-clicks for any tool except the Hand (the Grabber has the Hand and every right-click). Targeting `POINT` or `BUDDY` tools run press then release at once. `HOLD` and `DRAG` tools stay active and get `hold()` every physics step until the button comes up.
- **Behaviors** live in [scripts/tools/behaviors/](../scripts/tools/behaviors/) and extend `ToolBehavior`. Similar tools share one and differ by data: `spawn_in_hand_tool` (ball, brick, grenade), `drop_tool` (anvil, mini-nuke), `swing_tool` (bat, katana). A behavior reaches the world only through `sandbox` (the main scene, class `Sandbox`).
- **To add a tool:** write a behavior (or reuse one), add a `.tres` with its params, and draw an icon case in `ToolArt.draw_icon`. Add a test to `tests/test_tools.gd`.

### Shared tool systems (on `Sandbox`)

- `spawn_object(kind, at, velocity)`: a `WorldObject` (ball, brick, anvil, grenade, rocket, nuke). Kinds are data in `WorldObject.KINDS`: shape, mass, bounce, `impact_scale` (how hard its hits count against the Buddy), and for explosives a fuse and a blast. At most 40 loose objects; the oldest go first.
- `explode(at, radius, power, damage, sever_chance, source, sever_target)`: pushes every body outward with falloff, hurts the Buddy's nearest part, may blow limbs off, sets off nearby explosives (anything in the `explosive` group with `prime()`), scorches the room, flashes, shakes the camera and booms.
- `place_landmine`, `stick_dynamite`, `add_pin` / `remove_pin_near`, `spawn_black_hole`: placed items in `scripts/world/placed/`.
- `fx.add(seconds, painter)`: short visual effects. `Fx` has ready-made painters (flash, ring, bolt, sparks, smoke, screen flash).
- `add_shake(amount)`: camera shake.

### Buddy status effects

- `sever(limb, kick, source)`: cuts a limb off. The limb becomes a detached `BuddyPart` (debris that draws itself, can be grabbed as an object, removed by Clean Up). The stump bleeds and is drawn on the torso. No legs means it can't stand.
- `ignite(seconds)`: soot and damage over time, and it runs around in a panic. `freeze(seconds)`: holds its pose as a statue; hits do 1.5x damage; fire thaws it. `shock(seconds)`: twitching. `levitate(on)`: telekinesis holds it without counting as a grab.
- `notice(kind)`: tells the mind about things that aren't hits (poke, pin, bomb nearby). Hits carry `source` (a tool or object kind), so reactions can be specific: shot, batted, stabbed, crushed by an anvil, blown up.

## Saving

`Profile` holds everything saved. `Profile.from_dict` treats every value as possibly missing or wrong, and keeps unknown keys in `extra` so data from a newer version survives a round trip. JSON turns every number into a float, so convert with `int()` when loading.

`SaveStore` handles files and knows nothing about the data.

### File format

`user://save/save.json` is a one-line JSON header followed by the pretty JSON body:

```
{"checksum":"<sha256 of the body>","format":"best_fwend_save","saved_at":<unix>,"version":1}
{ ...profile... }
```

### Safety

- Each save writes `save.tmp`, reads it back to verify it, moves the old `save.json` to `save.prev.json`, then renames the temp file into place.
- **Backups:** `backups/backup_<unix>.json`, at most one per 10 minutes, keeping 5.
- **Reading order:** `save.json`, `save.tmp`, `save.prev.json`, then backups newest first. The first copy that passes its checksum wins, and the player is told if it wasn't the main file.
- **A damaged main file** is renamed `corrupt_<unix>.json` when next saved over.
- **Nothing that can't be read is overwritten.** If no copy is readable, or the save is from a newer version, the session runs without saving and says so.

### Changing the format

1. Raise `CURRENT_VERSION` in [save_migrations.gd](../scripts/core/save_migrations.gd).
2. Add a step to `steps()`, keyed by the version it upgrades from.
3. Add a test with a save from the old version. Never edit a shipped step.

The original file is kept once as `pre_v<N>.json`. Adding a new key read with a default doesn't need a migration; renaming or changing the meaning of data does.

## Physics

- 120 physics ticks per second, gravity 1960 px/s², 24 solver iterations. The Buddy is about 250 px tall.
- Collision layers live in `Layers`: walls 1, Buddy 2, objects 4. Buddy parts don't collide with each other.
- The walls are one `StaticBody2D` with bounce 0.3 and friction 0.9. The floor is at y = 880 so the toolbar sits on the floorboards, below anything standing.

## The Buddy

[buddy.gd](../scripts/world/buddy/buddy.gd) builds six `BuddyPart` rigid bodies (head, torso, two arms, two legs) pinned to the torso with `PinJoint2D`s. Keep the `Buddy` node at the origin: the parts move, not it.

- **Bend limits are ours, not the engine's.** Godot's 2D joint angle limits keep adding energy, so a resting body never settles. `_enforce_limits` nudges the spins of a limb and the torso when the limb bends past its range.
- **States:** `RAGDOLL` (limp), `GETTING_UP` (standing forces fade in over 0.8 s), `STANDING` (balancing and wandering), `GRABBED`. It gets up once it has been calm near the ground for 0.6 s.
- **Standing** is a spring that holds the torso at hip height above the ground (a ray along gravity), plus spin steering that keeps the torso, head and legs upright. Walking is a sideways force and a leg-swing angle. Everything is relative to gravity, so it stands on whichever wall gravity points at, and goes limp in zero-G.
- **Falls:** tipping past 1 rad, no ground for 0.3 s, or any hit over `KNOCKDOWN_DV`.
- **Impacts:** `BuddyPart._integrate_forces` measures how much a contact changed the part's velocity, counting only changes that push back against how fast the surfaces were closing (Godot's reported 2D contact impulses are unreliable). That drives squash and `Events.buddy_hit` (`force` is in px/s of velocity change; a hard wall slam is 2,000-5,000).
- **Drawing:** [buddy_view.gd](../scripts/world/buddy/buddy_view.gd) draws all parts from their transforms: head and torso outlines first so they read as one blob, limbs shifted onto their joints so brief stretch never shows a gap, squash along the last impact or stretch along motion, and a face with expressions picked from state.
- **Lost:** a part outside the room or a NaN position emits `lost`, and the sandbox respawns it.

### Health and hits

**Everything that hurts the Buddy calls `buddy.take_hit(info)`**: wall impacts today, tools in Milestone 4. It works out damage from `force` (or takes an explicit `damage`), leaves a bruise or blood mark on the part, knocks a standing Buddy over, lowers health, and emits the local `hit_taken` and global `Events.buddy_hit`.

- Damage starts at 1,400 px/s of velocity change (a fall from standing height doesn't hurt) at 0.013 per px/s, times the part's multiplier (head 1.5, limbs 0.6-0.7). A 3,000 slam does about 20.
- At 0 health it's knocked out: limp, silent, X eyes and stars. It revives after 6 s, or when clicked (a grab released within 0.25 s without moving), with 35 health. It heals 4/s after 4 s without damage.
- `Events.buddy_health_changed` drives the HUD bar.

### Personality

- [buddy_mind.gd](../scripts/world/buddy/buddy_mind.gd) picks reactions from context: hit strength, part and source, being grabbed (and by what), dangling, upside down, thrown, landing after flight, spinning (dizzy), getting up hurt, healing, idle time, gravity, slow-mo and cleaning. There's no mood meter (a design decision).
- Each situation has a priority (higher interrupts lower), a cooldown, and lines that don't repeat back to back. Lines live in [buddy_lines.gd](../data/lines/buddy_lines.gd); every situation in `BuddyMind.PRIORITY` must have lines (a test checks).
- [speech_bubble.gd](../scripts/world/buddy/speech_bubble.gd) types lines out with babble blips, follows the head and stays on screen.
- Faces: `BuddyView.pick_expression()` goes KO > ouch (recent hit) > the mind's `show_face()` > grabbed > scream (flying) > groggy (getting up or low health) > happy.
- Idle bits (`play_idle`: tap foot, look around, yawn) only run while standing still.

## Sound

`Sfx` (autoload) synthesizes every sound at startup with [synth.gd](../scripts/audio/synth.gd): voiced tones with vowel colour for babble, squeaks, yelps, grunts, screams, and filtered noise for thuds and splats. No audio files. `Sfx.play(name, volume_db, pitch)` and `Sfx.babble(pitch)` use a pool of players on the SFX bus. Music is still to come.

## Blood

`Blood` listens for damaging hits: it splats the impact point and throws droplets that fly under the current gravity and stain where they land. Stains go into `DecalLayer`, one half-resolution image drawn over the room background, so they cost nothing to keep. Clean Up wipes stains and flying drops; skin marks stay until respawn.

## The Hand

[grabber.gd](../scripts/world/grabber.gd) picks the grabbable body under the cursor (Buddy parts by `pick_priority`, then closest) and each physics step applies a critically-damped-ish spring force toward the cursor at the grabbed point. The Buddy's whole weight hangs from that point so the rest dangles, while 55% of the chasing force goes to the torso so limbs lead without tearing loose. Release scales velocities by `THROW_BOOST` and caps them at `MAX_THROW_SPEED`. The target is clamped inside the room.
- Gravity changes go through `main.set_gravity`, which sets the space's default gravity and wakes sleeping debris.
- Slow-mo sets `Engine.time_scale`. Physics still steps 120 times per real second, with smaller steps, so it stays smooth.
- Anything Clean Up should remove joins the `debris` group.

## Goals: stats, achievements, daily challenges, prestige

- **Stats:** `Game.record(stat, amount)` adds to `profile.stats`, or keeps the best for stats in `GoalData.MAX_STATS`. [tracker.gd](../scripts/world/tracker.gd) turns events into stats (throws, hits, knockouts, limbs, explosions, combo, flight, tool uses, play time). `Game.earn` records `earned`, except achievement and daily rewards so goals can't pay for themselves.
- **Achievements** are data in [goals.gd](../data/goals.gd) (`GoalData.ACHIEVEMENTS`: name, description, stat, goal, reward). Every `record` checks them (`Goals.pending_unlocks`); unlocking pays, saves and emits `achievement_unlocked`. `tools_owned` and `looks_owned` are computed from the profile.
- **Daily challenges:** `GoalData.DAILIES` templates with easy/medium/hard goals. `Game.daily()` makes three for today from templates whose tool you own (the same date always gives the same set) and they pay once when done. Uses the local date; `Game.date_override` fakes it in tests.
- **Prestige:** after earning `PRESTIGE_BASE x (level + 1)` in a run, `Game.prestige()` wipes $$$, tools and upgrades and adds +25% to `reward_multiplier()`. Looks, achievements, stats, best scores and today's challenge progress stay.
- Rules are plain functions in [goals.gd](../scripts/core/goals.gd) so they're testable without the game running.

## Minigames

[minigames.gd](../scripts/minigames/minigames.gd) starts one from a clean room, normal gravity and a fresh Buddy, and on `finish()` saves the best score, records `best_<id>`, pays `reward_for(score)` and emits `minigame_finished`. A game extends `Minigame`: set `time_left`, override `begin / tick / score_text / reward_for / cleanup`, and call `finish()`. `cleanup()` must undo anything it changed: `ToolUser.locked` and `Grabber.locked` (Hand only / no regrab), `Buddy.invulnerable`.

- **Ricochet:** one throw, score is distance travelled in metres until it rests.
- **Target Toss:** 45 s, hits count while the Buddy flies free.
- **Impact Frenzy:** 30 s, any owned tools, score is damage, the Buddy can't be knocked out.

## Looks (colours, skins, rooms)

- All looks are data in [cosmetics.gd](../data/cosmetics.gd): `COLORS`, `SKINS`, `ROOMS`. The first entry of each is free. A skin is a combination of a `pattern` (on the skin), a `back` piece (behind the head: ears, horns, antennae), a `hat` and a `face` piece. Purely cosmetic: nothing changes gameplay.
- `Game.look_status / buy_look / equip_look(kind, id)` with kind `&"color"`, `&"skin"` or `&"room"`. Buying also equips. `Events.looks_changed` makes the sandbox apply them live (`Sandbox.apply_looks`) and the Buddy comment.
- Saved in the profile: `owned_colors` + `buddy_color` (hex), `owned_skins` + `skin`, `owned_backgrounds` + `background`. A save can't wear anything it doesn't own.
- Drawing: [skin_art.gd](../scripts/ui/skin_art.gd) (skins, and the shop's standing-Buddy preview) and [background_art.gd](../scripts/ui/background_art.gd) (each room, drawn over the full room; props kept clear of the HUD). Review both with `tests/looks_sheet.tscn` (same command as the art sheet).
- Shop tabs 5-7 are Colors, Skins and Rooms, each card a live preview in your current look.

To add a skin: add an entry to `SKINS` using existing pieces, or add a new case to the matching `SkinArt` function. To add a room: add to `ROOMS` and a case in `BackgroundArt.draw`.

## Art

Tool and object art is vector, drawn in code with one style kit, [art.gd](../scripts/ui/art.gd): every shape gets an ink outline, a base fill, a shadow on its lower right and a highlight on its upper left (light from the upper left), so everything matches. [tool_art.gd](../scripts/ui/tool_art.gd) holds each drawing in a 100 x 100 design box; the toolbar icon, the object in the room and the weapon at the cursor all call the same function with a different transform. New art goes there, then check it on the art sheet (see README).

## Coding standards

- Follow the GDScript style guide: `snake_case` functions and variables, `PascalCase` classes, `CONSTANT_CASE` constants, tabs.
- Static typing everywhere practical. Annotate parameters and returns.
- Private members start with `_`. Other scripts don't touch them (tests may).
- Each script starts with a `##` line saying its job. Comments explain why, not what.
- Colors and the Theme live in `UiTheme`, icon art in `ToolArt`, tunable numbers in named constants or data.
- Content is data: tools now; skins, backgrounds, achievements and minigames later.
- No abstraction until there are two real uses for it.
- `set_anchors_preset` on a node already in the tree keeps its size; use `set_anchors_and_offsets_preset`.

## Testing

**A test launch never touches the player's save.** Any scene under `res://tests/` makes `Game` use `user://tests/`, and `++ --sandbox` sends a normal launch to `user://sandbox`.

Every system gets tests in `tests/test_*.gd`, listed in `run_tests.gd`. Commands are in the [README](../README.md).

- Test methods must end with `return true`.
- Call `reset_game("folder")` before touching `Game`.
- Headless runs can't show how things look. After visual changes, run the screenshot tool and look.
- Physics tests count physics frames, never real time, and run with `--fixed-fps 120`. Anything random (wandering) must pass on any seed: assert on totals, not exact paths.
- Every new feature gets debug cheats (F9 adds $$$ 1,000 in debug runs) and a test.
