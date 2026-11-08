# Best Fwend 1.0.0: QA report

Milestone 8. What was tested, what was found and fixed, and what's still known.

## How it was tested

- **Automated suite:** `tests/run_tests.tscn`, every suite headless at a fixed 120 Hz. It covers saves (including corrupt and newer-version saves), the Buddy's physics and reactions, every one of the 36 tools, the shop, looks, goals, prestige, all three minigames and release QA. Release QA plays from a fresh save and from a fully progressed save, round-trips a maxed save through disk, presses every dev-tool button, plays every minigame to the end, uses every tool from a maxed save and checks performance under heavy load.
- **Balance bot:** `tests/probe_progress.tscn` plays the real game from a fresh save like a steady player. It uses a tool every ~2 s, throws ~30% of the time, revives and respawns, and buys the cheapest tool it can afford. It covers the whole fresh-save → all-tools path end to end.
- **Screenshots:** `tests/shots.tscn` renders the real game, including every prestige weapon in action, Zombie Mode, the windows and other window sizes. `tests/art_sheet.tscn` and `tests/prestige_sheet.tscn` render every icon and object.
- **Export smoke test:** the exported `BestFwend.exe` was started headless on a throwaway save and exited cleanly.

## Bugs found and fixed in Milestone 8

| Bug | Fix |
|---|---|
| The economy was ~10× too generous: the bot owned every base tool in 11 minutes. | Hit pay and bonuses halved, base prices ~3.3× higher, anvil pays 60%, prestige at 300,000. See Balance below. |
| A wrecking ball used near a wall could start inside the wall and get spat out, missing completely. | It now swings out toward the side with room, at a shallower angle if needed. |
| Shattered-ice chunks were sometimes concave, which Godot warned about and simulated poorly. | Chunks use the convex hull of their points. |
| A slanted meteor drew its flame trail at the wrong angle. | Fixed the angle maths. |
| Locked prestige slots showed a price even though you can't buy them yet. | They say "PRESTIGE" until a prestige unlocks them. |
| Land Shark leapt too high and often missed. | Lower leap from just short of the target; it bites on the way up. |
| The tornado looked like stacked plates and hid what it carried. | Redrawn as a see-through, swirling funnel. |

## Balance

Target (the creative director's choice): a normal player owns all 21 base tools in about two hours.

| | Before | After |
|---|---|---|
| Hit pay | 1.6 per damage, force/500 | 0.8 per damage, force/1000 |
| Bonuses (limb / KO / shatter) | 30 / 80 / 200 | 15 / 40 / 100 |
| All 21 base tools cost | 70,750 | 234,900 |
| Anvil payout | 100% | 60% (it out-earned everything) |
| First prestige needs | 50,000 earned | 300,000 earned |
| Prestige weapons | 30,000–70,000 | 120,000–280,000 |

The balance bot (a tool every ~2 s, never idle, always buying the cheapest tool) on the new numbers:

| Game time | Tools owned | $$$ earned |
|---|---|---|
| 1 min | 3 (Poke, Ball, Slap) | 700 |
| 10 min | 9 | 13,000 |
| 20 min | 13 | 36,000 |
| 30 min | 16 | 65,000 |
| 42 min | 18 (through Rocket Launcher) | 92,000 |

Before the change the same bot owned all 21 in 11 minutes. It was stopped at 42 minutes. At its late rate (~2,300 $$$/min) the last three tools (Telekinesis, Black Hole, Mini-Nuke: 148,000) land at roughly **95–105 bot minutes**. That part is projected, not run. A person plays slower than a bot that never stops (menus, watching, petting), so that's about two hours for a normal player. Achievements paid ~12% and knockouts ~15% of earnings; no single tool dominates.

## Performance

Physics runs at 120 Hz, so a frame has 8.3 ms. Measured headless on the development PC with five zombies, 40 objects, a tornado and a black hole all at once (far beyond normal play): **6.8 ms average, 20 ms worst spike**. Normal play is a fraction of that. The music loop is built on a worker thread in ~0.4 s at startup, so loading doesn't wait for it.

## Known limitations

- **Windows only, mouse only.** No controller, touch or keyboard-only play. No web, Mac or mobile builds.
- **Not code-signed.** Windows SmartScreen may warn on first launch ("More info" > "Run anyway").
- **Private repository.** The download link only works when you're signed in to the GitHub account that owns it.
- **Physics is real-time.** With 40 objects, five zombies and a tornado at once, a slow PC can drop physics steps and briefly run in slow motion. Normal play is far below that.
- **Daily challenges use the PC's clock.** Changing the date changes the challenges.
- **No pause** (by design). Music is one 16-second loop.
- **Test-only warning:** the test runner reports "ObjectDB instances leaked at exit". The real game exits clean (checked with `--verbose`).
