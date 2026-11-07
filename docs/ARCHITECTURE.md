# Architecture

The Buddy's physics, the tools, the economy and the UI must grow without knowing each other's internals. They talk through `Events`, read shared state from `Game`, and describe content with data.

## Folder structure

```
data/tools/        One ToolDef .tres per tool. Adding one adds it to the toolbar.
scenes/            main.tscn (the sandbox).
scripts/main.gd    The sandbox: room, world, HUD; slow-mo, gravity, clean up, shortcuts.
scripts/core/      Services with no UI or physics: Events, Game, Profile, SaveStore, etc.
scripts/data/      Resource classes and catalogs (ToolDef, ToolCatalog).
scripts/world/     Things in the physics world: Room, Grabber (the Hand), Layers, TestBall.
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

Don't add an autoload for a feature. New systems (economy, achievements) become plain objects owned by `Game` or the sandbox, so tests can build them on their own.

## Events

Declared in [events.gd](../scripts/core/events.gd), many ahead of the milestone that first emits them.

- Use `Events` when the emitter shouldn't know who listens: "the Buddy was hit", "$$$ was earned". Achievements, rewards and stats will listen here.
- Use a local signal when only the owner cares, as the HUD does with `main.gd`.
- Call a method when you need a result or own the target: `Game.spend(...)`, `room.clear_decals()`.
- Name signals in the past tense. Give them typed parameters.
- Listeners must not assume an order among themselves.

`buddy_hit` carries a Dictionary (`part`, `force`, `source`, `damage`, `position`) so new hit types don't need new signals.

## Money

`Game.earn(amount, reason)` and `Game.spend(amount, reason) -> bool`. Both emit events and mark the save dirty. Amounts are ints; `Fmt.money` shows them as `$$$ 1,234`. The reward formula (force, variety combo, diminishing repeats) arrives in Milestone 5 and will call `earn`.

## Tools

A tool is a `ToolDef` resource in `data/tools/` with its name, category, price, strength, targeting and a `behavior` script (Milestone 4). `ToolCatalog` finds every file there, so nothing else needs registering. Tools are unlimited: `use_interval` exists only to rate-limit held tools like the pistol, never as a cooldown.

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

## The Hand

[grabber.gd](../scripts/world/grabber.gd) picks the grabbable body under the cursor (Buddy parts by `pick_priority`, then closest) and each physics step applies a critically-damped-ish spring force toward the cursor at the grabbed point. The Buddy's whole weight hangs from that point so the rest dangles, while 55% of the chasing force goes to the torso so limbs lead without tearing loose. Release scales velocities by `THROW_BOOST` and caps them at `MAX_THROW_SPEED`. The target is clamped inside the room.
- Gravity changes go through `main.set_gravity`, which sets the space's default gravity and wakes sleeping debris.
- Slow-mo sets `Engine.time_scale`. Physics still steps 120 times per real second, with smaller steps, so it stays smooth.
- Anything Clean Up should remove joins the `debris` group.

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
