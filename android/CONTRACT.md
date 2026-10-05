# Project Delta Android — Module Contract (as built)

`ui/` + `ads/` are written against the `game/` and `characters/` modules below.
These are the ACTUAL implemented signatures — both sides already agree.

## game/GameEngine.kt — `com.emckeon97.projectdelta.game`

Plain-Kotlin endless-runner simulation (no Compose/coroutine dependency).
No-arg constructor. The renderer (`GameRenderer`) owns the frame loop and
calls `update(dtMs)`; geometry (`applyGeometry`) is set from the canvas size.

```kotlin
class GameEngine() {
    // renderer-provided geometry (px)
    var laneSpacing: Float
    var playerY: Float
    var screenH: Float
    fun applyGeometry(spacing: Float, pY: Float, sH: Float)

    // player (read-only outside)
    var playerLane: Int;  var playerX: Float
    var playerState: PlayerState   // RUNNING | JUMPING | ROLLING
    var jumpPx: Float
    val rolling: Boolean

    // run state (read-only outside, except where noted)
    var speed: Float
    var score: Int                // meters
    var coinsCollected: Int
    var gameOver: Boolean
    val obstacles: MutableList<Obstacle>
    val coins: MutableList<Coin>
    val powerups: MutableList<PowerUp>
    val magnetActive: Boolean
    val multiplierActive: Boolean

    // UI integration (written by the UI agent)
    var paused: Boolean = false   // renderer skips update() while true

    // input
    fun moveLeft()
    fun moveRight()
    fun jump()
    fun roll()

    /** Fresh run: reset everything, clear paused/gameOver. */
    fun reset()

    /** Post-rewarded-ad revive: keep score/coins, clear threats, 2s invincibility. */
    fun revive()

    /** Advance simulation by dtMs. No-op when gameOver. */
    fun update(dtMs: Long)
}
```

Mechanics: 3 lanes; obstacles BARRIER (jump) / OVERHEAD (roll) / TRAIN
(change lanes), never all 3 lanes blocked per row; coins in lines/arcs/zigzag;
MAGNET + MULTIPLIER power-ups (8s); speed 420 → 950 px/s; score = distance.

## game/GameCanvas.kt — `com.emckeon97.projectdelta.game`

```kotlin
@Composable
fun GameRenderer(
    engine: GameEngine,
    characterID: String,
    modifier: Modifier = Modifier,
    onGameOver: () -> Unit = {}   // fired exactly once per run end
)
```

Owns the 60fps `withFrameNanos` loop: `applyGeometry` on size change,
`engine.update(dtMs)` while `!engine.gameOver && !engine.paused`, draws
background/lanes/coins/obstacles/power-ups/player (via `drawCharacter`).
`GameScreen` passes `onGameOver` to navigate to the GameOver route.

## characters/GameCharacter.kt — `com.emckeon97.projectdelta.characters`

```kotlin
data class GameCharacter(val id: String, val name: String, val price: Int, val tagline: String)

val ROSTER: List<GameCharacter>  // willie 0, felix 500, oswald 1000, popeye 2500, pooh 5000, betty 10000
```

## characters/CharacterManager.kt — `com.emckeon97.projectdelta.characters`

```kotlin
class CharacterManager(context: Context) {
    val coins: StateFlow<Int>
    val selectedID: StateFlow<String>        // default "willie"
    val unlockedIDs: StateFlow<Set<String>> // default setOf("willie")
    val highScore: StateFlow<Int>
    val characters: List<GameCharacter>     // ROSTER
    val selectedCharacter: GameCharacter
    fun isUnlocked(c: GameCharacter): Boolean
    fun unlock(c: GameCharacter): Boolean   // false if can't afford / already unlocked
    fun select(c: GameCharacter)            // no-op unless unlocked
    fun addCoins(n: Int)
    fun recordScore(s: Int)
}
```

SharedPreferences file `"projectdelta"`, keys `delta.coins`, `delta.selected`,
`delta.unlocked`, `delta.highscore` (same as iOS UserDefaults keys).

## characters/CharacterDraw.kt — `com.emckeon97.projectdelta.characters`

Top-level `DrawScope` extension (NOT inside an object):

```kotlin
fun DrawScope.drawCharacter(
    id: String,        // "willie" | "felix" | "oswald" | "popeye" | "pooh" | "betty"
    centerX: Float,    // px, horizontal center of the character
    feetY: Float,      // px, ground-contact y
    size: Float,       // px, total character height
    rolling: Boolean   // compact tumbling ball when true
)
```

Rubber-hose black-and-white vector art, no assets.
