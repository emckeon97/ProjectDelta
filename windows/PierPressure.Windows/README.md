# Pier Pressure — Windows Port (.NET MAUI)

A Windows port of **Pier Pressure**, the 1930s 3D endless runner starring
public-domain cartoon characters. Direct port of the Android version's
perspective-projected 3D engine — same tuning, same art direction, same
Kevin MacLeod ragtime loop.

## Tech

- **.NET 10 MAUI**, Windows-only target (`net10.0-windows10.0.19041.0`)
- **SkiaSharp** for the 60fps perspective-3D game canvas
  (camera at height 5, z = −8; `screenX = cx + x·s`, `screenY = horizonY + (H−y)·s`)
- MAUI XAML for menu / character select / game-over screens
- `Windows.Media.Playback.MediaPlayer` for the music loop (no extra packages)

## Build it (on Windows)

You need the **.NET 10 SDK** and **Visual Studio 2026** with the
“.NET Multi-platform App UI development” workload.

```powershell
cd windows\PierPressure.Windows
dotnet restore
dotnet build -c Release
dotnet run -c Release -f net10.0-windows10.0.19041.0
```

Or open the `.csproj` in Visual Studio and press F5 (target: Windows Machine).

> MAUI Windows targets must be built on Windows (your Parallels VM works).

## Controls

- **Swipe left / right** (mouse-drag works) — change lane
- **Swipe up** (or tap) — jump
- **Swipe down** — roll
- ⏸ button — pause

## Art & music (copy these in)

Binaries don't live in git. Copy from the iOS project on your Mac:

| File | From (Mac) | To (here) |
|------|-----------|-----------|
| `felix.png` … `pete.png` (9 sprites) | `~/Documents/ProjectDelta/ProjectDelta/Sprites/` | `Resources/Raw/` |
| `delta_ragtime.mp3` | `~/Documents/ProjectDelta/ProjectDelta/Resources/` | `Resources/Raw/` |

Without sprites the toons render as ink silhouettes; without the MP3 it's silent.

## Project map

| File | What |
|------|------|
| `Game/DeltaEngine.cs` | 3D endless-runner engine: lanes, jump/roll, obstacles, coins, power-ups, reels, collisions (port of Android `GameEngine.kt`, same tuning) |
| `Game/DeltaRenderer.cs` | Perspective-3D SkiaSharp renderer: night sky, riverboat, pier, rowboats, footbridges, paddle-wheelers, coins, power-ups, squash-and-stretch player (port of Android `GameCanvas.kt`) |
| `Characters/Roster.cs` | 12 public-domain toons, prices, reel title cards |
| `Services/CharacterService.cs` | Coin wallet, unlocks, high score, selected toon (persisted) |
| `Services/MusicService.cs` | Ragtime loop + mute (persisted) |
| `Views/MenuPage` | Marquee menu |
| `Views/CharacterSelectPage` | 12-toon roster with coin unlocks |
| `Views/GamePage` | 60fps loop + swipe input + reel cards + HUD |
| `Views/GameOverPage` | "THE END" card |

## Notes

- **No ads on Windows.** The mobile ports use AdMob; there is no AdMob for
  MAUI Windows, so the Windows port is the premium edition — no interstitials,
  no rewarded revive. (The revive path is simply absent.)
- Coins, unlocks, high score, selected toon, and mute persist via MAUI
  Preferences (same keys as the mobile ports: `delta.*`).
