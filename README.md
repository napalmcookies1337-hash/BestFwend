# Best Fwend

A physics buddy sandbox: fling, smash and blow up your round blob fwend to earn $$$, then spend it on more ways to ruin its day. Built with Godot 4.6 and GDScript for Windows.

- [DESIGN.md](DESIGN.md): the approved game design brief.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code is organized, and the rules for adding to it.

Current state: Milestone 7. Your fwend lives in the room with 21 tools: poke, slap, tickle and pin it; throw balls and bricks; drop anvils; swing a bat or katana; grenades, sticky dynamite, landmines, a pistol, rockets and a mini-nuke; lightning, fire, a freeze ray, black holes and telekinesis. Limbs come off. Hurting your fwend earns $$$ (more for variety, less for spamming one tool, bonuses for limbs, knockouts and shattering), which buys tools and upgrades in the Shop. You start with only the Hand. A frozen fwend that gets knocked out shatters into ice. The shop also sells 11 colours, 10 skins (hats, ears, horns, shades, patterns) and 6 rooms. The Goals window has 26 achievements, three daily challenges and prestige. Each prestige unlocks one random prestige weapon for the Shop (30,000-70,000 $$$); bought ones are kept through later prestiges. There are 15 of them, filling the rest of the toolbar: Giant Fist, Mega Clap, Slingshot, Spin Cycle, Wrecking Ball, Chainsaw, Falling Piano, Saw Launcher, Cluster Bomb, Airstrike, Rocket Pack, Tornado, Meteor Shower, Orbital Laser and Land Shark. The Minigames button has Zombie Mode (2 minutes, waves of five zombies chasing your cursor), Target Toss and Impact Frenzy.

The Buddy's lines are in [data/lines/buddy_lines.gd](data/lines/buddy_lines.gd). Edit them freely.

## Run the game

```
D:\ClaudeCode\BestFwend\Play.bat
```

To try something without touching your real save, add the sandbox flag:

```
D:\ClaudeCode\BestFwend\Play.bat ++ --sandbox
```

Mouse: **left-click** uses the selected tool (with the Hand, left-drag grabs and throws). **Right-drag** always grabs and throws, whatever tool is selected. Pick tools from the toolbar tabs or with **1-9**.

Keys: **R** respawn, **C** clean up, **T** slow-mo, **1-9** tools, **F11** fullscreen, **Esc** closes menus. In debug runs, **F9** adds $$$ 1,000, **F8** drops a test ball at the cursor and **F7** unlocks every tool.

To see how fast $$$ comes in under different play styles:

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --headless --path D:\ClaudeCode\BestFwend -s res://tests/probe_economy.gd
```

## Run the tests

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --headless --path D:\ClaudeCode\BestFwend --fixed-fps 120 res://tests/run_tests.tscn --quit-after 200000
```

`--fixed-fps 120` makes each frame exactly one physics step and stops waiting on the clock, so the physics tests (which simulate a minute or so of play) finish in seconds.

To tune the Buddy, `tests/probe_buddy.tscn` prints its state over time in a few scenarios (same command, that scene instead).

Look for `N passed, 0 failed` at the end; the exit code is non-zero on failure. Some tests feed in bad saves on purpose, so warnings about saves that "couldn't be read" or are "from a newer version" are expected. Tests only touch `user://tests`.

After adding a script with a new `class_name`, or on a fresh clone, import once:

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --headless --path D:\ClaudeCode\BestFwend --import --quit-after 600
```

## Screenshots

Renders the real game to `tests/shots/` using a throwaway save. Opens a window for a few seconds.

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --path D:\ClaudeCode\BestFwend --fixed-fps 120 --disable-vsync res://tests/shots.tscn --quit-after 40000
```

## Art sheet

Draws every tool icon, room object and held weapon on one screen to `tests/shots/art_sheet.png`. Opens a window for a moment.

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --path D:\ClaudeCode\BestFwend res://tests/art_sheet.tscn --quit-after 2000
```

`res://tests/prestige_sheet.tscn` does the same for the prestige weapons (`tests/shots/prestige_sheet.png`).

## Where saves live

`%APPDATA%\Godot\app_userdata\Best Fwend\save\`: `save.json`, `save.prev.json` and `backups\`.
