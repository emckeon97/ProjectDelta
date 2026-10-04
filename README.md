# Project Delta

A Subway Surfers-style endless runner starring **public-domain cartoon legends** — that's the edge. All character art is drawn in code (rubber-hose 1930s style, no assets).

## Roster (all public domain, unlockable with coins)
| Character | Price |
|---|---|
| Steamboat Willie | Free (starter) |
| Felix the Cat | 500 |
| Oswald the Lucky Rabbit | 1,000 |
| Popeye the Sailor | 2,500 |
| Winnie the Pooh | 5,000 |
| Betty Boop | 10,000 |

## Gameplay
3-lane runner, portrait. Swipe left/right to change lanes, up to jump, down to roll. Dodge barriers (jump), overhead bars (roll), and trains (switch lanes). Grab coins, magnet + 2x score power-ups. Speed ramps up the longer you survive.

## Targets
- **ProjectDelta** — iOS (iPhone/iPad), bundle ID `com.emckeon97.ProjectDelta`, with AdMob ads
- **ProjectDeltaMac** — Mac Catalyst, bundle ID `com.emckeon97.ProjectDelta.mac`, ads compiled out (AdMob doesn't link on Catalyst)

## Ads (Google AdMob)
Banner on menu/character screens, interstitial every 3rd game over, rewarded ad to revive after a crash. Currently using **Google test ad IDs** — flip `AdManager.useTestIDs` to `false` and fill in `REAL_*_ID` in `Ads/AdManager.swift` when production units are ready.

## Build
Open `ProjectDelta.xcodeproj` in Xcode, pick a target, run. Deployment target iOS 16.0.
