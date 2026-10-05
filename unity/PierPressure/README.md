# Pier Pressure — Unity 6 Edition

A 3D Subway Surfers-style endless runner starring public-domain 1930s cartoon
characters, rebuilt as a full Unity 6 project. Run down a moonlit wooden pier,
dodge rowboats, duck under footbridges, dodge the paddle-wheelers, grab coins,
and unlock all 12 toons.

## Requirements

- **Unity 6 LTS** (6000.x) with the **Windows Build Support** module
- **Unity Hub** to open the project

## Opening the project

1. In Unity Hub: **Add** → select this folder (`pier-pressure`).
2. Open it. Everything in the game world (track, player, UI, effects) is built
   **procedurally at runtime** by `Bootstrap.cs` — the scene file only holds a
   camera, a light, and the bootstrap marker, so there is nothing fragile to
   break.

## Optional art & music (binaries not in git)

The game runs 100% without these — missing sprites fall back to procedural
rubber-hose toon stand-ins and the music simply stays silent.

- **Character PNGs** (9 files): copy to `Assets/Resources/Characters/` (create
  the folder), exact filenames:
  `felix.png`, `popeye.png`, `oswald.png`, `koko.png`, `bimbo.png`,
  `pooh.png`, `olive.png`, `bosko.png`, `pete.png`
  - In Unity, select each PNG → Inspector → **Texture Type: Sprite** → Apply.
    (Required — the game loads them with `Resources.Load<Sprite>`.)
- **Music**: copy `delta_ragtime.mp3` to `Assets/Resources/Music/`
  (`Assets/Resources/Music/delta_ragtime.mp3`).

## Building for Windows

1. **File → Build Settings…**
2. Platform: **Windows, Mac, Linux** → Target Platform **Windows**,
   Architecture **x86_64**.
3. **Add Open Scenes** (adds `Assets/Scenes/Main.unity`).
4. **Build** (or Build And Run).

## Controls

| Action | Touch / Mouse | Keyboard |
|---|---|---|
| Change lane | Swipe left/right | ←/→ or A/D |
| Jump (rowboats) | Swipe up | ↑, W, or Space |
| Roll (footbridges) | Swipe down | ↓ or S |
| Pause | II button (HUD) | Esc or P |

Tap/click does nothing during gameplay — all menu navigation is via buttons.

## Roster & unlocks

Coins are banked across runs and spent in the Characters screen.

| Toon | Cost |
|---|---|
| Popeye | FREE (starter) |
| Felix | 500 |
| Oswald | 1,000 |
| Minnie | 1,500 |
| Mickey (Steamboat Willie) | 2,500 |
| Koko | 3,000 |
| Bimbo | 4,000 |
| Pooh | 5,000 |
| Olive | 6,500 |
| Bosko | 8,000 |
| Betty | 10,000 |
| Peg-Leg Pete | 12,000 |

Minnie, Mickey, and Betty have no sprite art — they render as procedural
3D-primitive cartoon stand-ins. Three random non-player toons wave from the
pier sidelines and the riverboat as you run.

## Power-ups

- **Magnet** (blue): pulls nearby coins to you, 8s.
- **2x** (green): doubles your score multiplier, 8s.

## Music credit

"The Entertainer" — Kevin MacLeod (incompetech.com), licensed CC-BY 4.0.

## Trademark note

Oswald, Popeye, Betty, and Bosko have live trademarks held by their owners.
Using the public-domain character designs in-game is fine, but do **not** put
those names in the game title, store listing title, or app icon.

## Project layout

- `Assets/Scripts/` — all game code (see headers in each file).
- `Assets/Scenes/Main.unity` — minimal scene (camera + light + bootstrap).
- `Assets/Resources/Characters/`, `Assets/Resources/Music/` — your copied
  binaries go here (folders not in git).
- `ProjectSettings/` — Unity 6 project settings.
