# Best Fwend

A physics buddy sandbox: fling, smash and blow up your round blob fwend to earn $$$, then spend it on more ways to ruin its day. Built with Godot 4.6 and GDScript for Windows.

- [DESIGN.md](DESIGN.md): the approved game design brief.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code is organized, and the rules for adding to it.

Current state: Milestone 1. The room, HUD shell, settings, slow-mo, gravity, and the save system work. The Buddy arrives in Milestone 2.

## Run the game

```
D:\ClaudeCode\BestFwend\Play.bat
```

To try something without touching your real save, add the sandbox flag:

```
D:\ClaudeCode\BestFwend\Play.bat ++ --sandbox
```

Keys: **R** respawn, **C** clean up, **T** slow-mo, **1-9** tools, **F11** fullscreen, **Esc** closes menus. In debug runs, **F9** adds $$$ 1,000.

## Run the tests

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --headless --path D:\ClaudeCode\BestFwend res://tests/run_tests.tscn --quit-after 60000
```

Look for `N passed, 0 failed` at the end; the exit code is non-zero on failure. Some tests feed in bad saves on purpose, so warnings about saves that "couldn't be read" or are "from a newer version" are expected. Tests only touch `user://tests`.

After adding a script with a new `class_name`, or on a fresh clone, import once:

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --headless --path D:\ClaudeCode\BestFwend --import --quit-after 600
```

## Screenshots

Renders the real game to `tests/shots/` using a throwaway save. Opens a window for a few seconds.

```
& "E:\GoDOT\Godot_v4.6.2-stable_win64_console.exe" --path D:\ClaudeCode\BestFwend res://tests/shots.tscn --quit-after 3000
```

## Where saves live

`%APPDATA%\Godot\app_userdata\Best Fwend\save\`: `save.json`, `save.prev.json` and `backups\`.
