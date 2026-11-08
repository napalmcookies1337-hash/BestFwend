# Best Fwend: Game Design Brief

Approved by the creative director on 2026-11-07. Change only with their approval.

## 1. Game identity
- **Name:** Best Fwend. Money is shown as **$$$**.
- **What it is:** A modern, original take on Interactive Buddy (Shock Value). It's a 2D physics toybox built around a round blob Buddy that you fling, smash, blow up, and occasionally pet. All characters, art, names, audio and code are original.
- **Tone:** Like the original, with gore. Blood splatters and leaves stains on walls and floor, and limbs can be blown or sliced off. It's cartoonish but messy. Gore is always on, with no toggle. **The Buddy swears.**
- **What makes it stand out:**
  - Much better physics feel than the Flash original, with squash and stretch and lots of feedback.
  - A Buddy that gets up and wanders around on its own.
  - An economy that rewards variety instead of grinding one action.

## 2. Core gameplay loop
1. You mess with the Buddy using whatever tool you like.
2. Bigger impacts and varied combos earn $$$.
3. $$$ buys new tools, upgrades, skins, and backgrounds.
4. New tools open new ways to mess with it, and the loop repeats.

There's no campaign. Achievements, daily challenges, and minigames are optional goals on top.

## 3. Buddy design
- **Look:** Round blob body, big expressive eyes, stubby arms and legs.
- **Face:** Drawn in code, so it can change instantly: pain, dizzy, KO, smug, scared-looking reactions.
- **Damage visuals:** Bruises, soot, and blood stay on the skin until the Buddy respawns.
- **Detached limbs:** They become physics objects you can grab and throw. The torso and head keep going, and the Buddy reacts to the missing parts.
- **Respawn button:** Reassembles a fresh Buddy at any time.

## 4. Physics behavior
- **Body:** A hybrid ragdoll. Six jointed rigid parts (head, torso, two arms, two legs) with angle limits on the joints, plus visual squash and stretch and jiggle on top.
- **Impacts:** Medium bounce with a big squash. Hard hits deal damage and spawn blood.
- **Health:** A health bar drains with damage. At zero the Buddy is KO'd and goes limp. It revives after a few seconds or when you click it, and slowly heals while left alone.
- **When left alone:** It rights itself, balances, waddles around, and does idle bits like watching the cursor, yawning, and tapping its foot.
- **Extra controls:** Slow-motion toggle; gravity tweak (strength and direction); Clean Up button that wipes blood and debris. No pause.

## 5. Player controls (Windows, mouse)
- **Hand tool:** Clicking any part of the Buddy grabs it. A strong spring pulls that point toward the cursor, so the rest dangles.
- **Throwing:** Releasing throws with your drag speed, up to a maximum.
- **Other tools:** With another tool selected, left-click uses that tool where you click. Right-click always grabs, whatever tool is selected.
- **Multi-grab:** One grab point, plus an unlockable Pin tool that nails a limb in place for stretching gags.
- **Tool switching:** From the toolbar, with 1-9 hotkeys.

## 6. Tool categories (21 tools, fully unlimited, no cooldowns)
| Hand | Throwables & Melee | Explosives & Weapons | Powers |
|---|---|---|---|
| Hand (grab/throw) | Rubber Ball | Grenade | Lightning |
| Poke | Brick | Sticky Dynamite | Ignite (fire) |
| Slap | Anvil (drops from above) | Landmine | Freeze Ray |
| Tickle Feather | Baseball Bat | Pistol | Black Hole |
| Pin | Katana (cuts off limbs) | Rocket Launcher | Telekinesis |
| | | Mini-Nuke | |

- **Prestige weapons (added 2026-11-07 at the creative director's request):** 15 more tools fill the rest of the toolbar (Giant Fist, Mega Clap, Slingshot, Spin Cycle; Wrecking Ball, Chainsaw, Falling Piano, Saw Launcher; Cluster Bomb, Airstrike, Rocket Pack; Tornado, Meteor Shower, Orbital Laser, Land Shark). Each prestige unlocks one at random for the Shop at a high price (120,000–280,000 $$$). Bought ones are kept through later prestiges.
- **Spawned objects:** Balls, bricks, anvils, and severed limbs stay in the room, collide with everything, and can be grabbed. The oldest ones despawn past a cap.
- **Tools are data-driven:** Each tool is a definition file plus a shared behavior script.

## 7. Currency and progression
- **Earning:** $$$ scales with impact force and damage. Using different tools in a row builds a combo multiplier, and repeating the same action pays less and less. Kind actions (petting, tickling) earn a small amount and count toward variety combos.
- **Spending:** Tools, tool upgrades (bigger blasts, more force, alternate modes), Buddy skins and colors, and backgrounds.
- **No ranks.** Price is the only gate, so cost curves pace progression.
- **Later milestones:** Achievements with rewards; daily challenges on the local clock; an optional prestige reset that gives a permanent $$$ multiplier.
- **Pacing (Milestone 8):** A normal player owns all 21 base tools in about two hours. The first prestige needs 300,000 $$$ earned in a run.

## 8. Buddy reactions
- **Speech:** Bubbles with written lines (with swearing), a gibberish babble voice, and squeaks and yelps.
- **No mood system.** Reactions depend on context, not random chance alone: what hit it, how hard, which limb, being airborne, KO, missing limbs, being grabbed, and idle time.

## 9. Customization and environment
- **Skins and colors:** Cosmetic only. The same personality in every skin.
- **Backgrounds:** Swappable only. The room is always a walled box, with no props and no layout editor.

## 10. Game modes
- **Sandbox:** The main mode.
- **Minigames (Milestone 7, revised):** Zombie Mode (2 minutes; your fwend is a zombie, five zombies at a time chase the cursor, kill as many as you can; replaced Buddy Launch/Ricochet at the creative director's request), Target Toss, Impact Frenzy (most damage in 30 seconds). They have their own Minigames button. Best scores are saved.

## 11. Technical direction
- Godot 4.6 and GDScript, 2D, Windows desktop, mouse. 16:9 base (1920x1080), resizable window.
- `RigidBody2D` parts joined with `PinJoint2D` with angle limits. The grab is a spring-damper force applied in the physics step. Physics runs at 120 Hz.
- Blood is painted into a persistent decal layer. Breaking a limb removes its joint.
- An event bus decouples UI, economy and achievements from physics.
- Versioned JSON saves in `user://`.
- Vector art drawn in code. Sound effects and babble synthesized in code, plus a simple looping music track (bouncy cartoon style: plucky bass, xylophone tune, oom-pah chords).

## 12. Milestones
1. Project shell, UI frame, save test.
2. The Buddy and the feel of grabbing and throwing.
3. Reactions and speech.
4. Toolbar and all 21 tools.
5. Shop and economy.
6. Skins and backgrounds.
7. Achievements, dailies, prestige, minigames.
8. Polish, balance, QA and a Windows build.

## 13. Long-term scope
More tools and secret tools, more skins and backgrounds, a web or mobile port, and more minigames, only with the creative director's go-ahead.

## 14. Assumptions (approved)
- Severed limbs disappear on respawn or Clean Up.
- No Steam or online features.
- Each milestone ends with a playable build and a report, then stops for feedback.
