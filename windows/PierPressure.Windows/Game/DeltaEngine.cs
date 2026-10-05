namespace PierPressure.Windows.Game;

public enum ObstacleKind { Barrier, Overhead, Train }
public enum PowerUpKind { Magnet, Multiplier }

/// <summary>
/// Plain-C# endless-runner engine (no UI dependency).
/// All gameplay runs in 3D world units:
/// x = lateral (lanes at -2.2, 0, 2.2), y = height above ground,
/// z = depth (player at z = 0, entities spawn at z = 60).
/// Direct port of the Android GameEngine — same tuning.
/// </summary>
public sealed class DeltaEngine
{
    public struct Obstacle
    {
        public int Lane; public double Z; public ObstacleKind Kind; public double Depth;
    }
    public struct Coin
    {
        public double X, Y, Z; public bool Collected;
    }
    public struct PowerUp
    {
        public double X, Z; public PowerUpKind Kind; public bool Taken;
    }

    // ---- tuning ----
    public static readonly double[] LaneX = { -2.2, 0, 2.2 };
    public const double StartSpeed = 10, MaxSpeed = 26, SpeedRamp = 0.5;
    public const double LaneLerp = 12, JumpTime = 0.88, JumpHeight = 3.5, RollTime = 0.75;
    public const double PlayerMidH = 0.8;
    public const double SpawnZ = 60, DespawnZ = -10;
    public const double TrainDepth = 6, ObstacleDepth = 1;
    public const double CoinY = 0.9, CoinGap = 1.6;
    public const double PowerDurationMs = 8000, PowerY = 1.2;
    public const double SafeStartS = 1.5, ReviveInvincibleMs = 2000;
    public const double ReelLength = 500;
    public const double LaneTolerance = 1.0, CollideZ = 1.0, BarrierClearH = 0.9;
    public const double CollectR = 1.0, CollectYR = 1.4, PickupR = 1.2, PickupYR = 1.6;
    public const double MagnetRadius = 6, MagnetPull = 14;

    // ---- player ----
    public int PlayerLane { get; private set; } = 1;
    public double PlayerX { get; private set; }
    public double PlayerY { get; private set; }
    public bool IsRolling { get; private set; }
    private int _state; // 0 run, 1 jump, 2 roll
    public double StateT { get; private set; }

    // ---- run state ----
    public double ScrollSpeed { get; private set; } = StartSpeed;
    public int Score { get; private set; }
    public int Reel { get; private set; } = 1;
    public bool ReelChanged { get; set; }
    public int CoinsCollected { get; private set; }
    public bool GameOver { get; private set; }
    public bool Paused { get; set; }
    public double Distance { get; private set; }

    public List<Obstacle> Obstacles { get; } = new();
    public List<Coin> Coins { get; } = new();
    public List<PowerUp> PowerUps { get; } = new();

    public bool MagnetActive { get; private set; }
    public bool DoubleScore { get; private set; }

    private double _magnetUntil, _multiplierUntil, _elapsedMs, _invincibleUntil;
    private double _rowTimer, _coinTimer, _powerTimer, _scoreAccum;
    private readonly Random _rng = new();

    // ---- input ----
    public void MoveLeft()  { if (!GameOver) PlayerLane = Math.Max(0, PlayerLane - 1); }
    public void MoveRight() { if (!GameOver) PlayerLane = Math.Min(2, PlayerLane + 1); }
    public void Jump()
    {
        if (GameOver || _state == 1) return;
        _state = 1; IsRolling = false; StateT = 0;
    }
    public void Roll()
    {
        if (GameOver || _state == 1) return;
        _state = 2; IsRolling = true; StateT = 0;
    }

    public void Reset()
    {
        PlayerLane = 1; PlayerX = 0; PlayerY = 0; IsRolling = false; _state = 0; StateT = 0;
        ScrollSpeed = StartSpeed; Score = 0; _scoreAccum = 0;
        Reel = 1; ReelChanged = true;
        CoinsCollected = 0; GameOver = false; Paused = false; Distance = 0;
        _invincibleUntil = 0;
        Obstacles.Clear(); Coins.Clear(); PowerUps.Clear();
        MagnetActive = false; DoubleScore = false;
        _magnetUntil = 0; _multiplierUntil = 0; _elapsedMs = 0;
        _rowTimer = SafeStartS; _coinTimer = 1; _powerTimer = 12;
    }

    public void Update(double dtMs)
    {
        if (GameOver || Paused || dtMs <= 0) return;
        double dt = dtMs / 1000.0;
        _elapsedMs += dtMs;

        MagnetActive = _elapsedMs < _magnetUntil;
        DoubleScore = _elapsedMs < _multiplierUntil;

        ScrollSpeed = Math.Min(MaxSpeed, StartSpeed + (_elapsedMs / 1000.0) * SpeedRamp);
        double dz = ScrollSpeed * dt;
        Distance += dz;

        double targetX = LaneX[PlayerLane];
        double dx = targetX - PlayerX;
        double step = LaneLerp * dt;
        PlayerX += Math.Max(-step, Math.Min(step, dx));

        if (_state == 1)
        {
            StateT += dt;
            double t = Math.Max(0, Math.Min(1, StateT / JumpTime));
            PlayerY = JumpHeight * Math.Sin(Math.PI * t);
            if (StateT >= JumpTime) { _state = 0; PlayerY = 0; }
        }
        else if (_state == 2)
        {
            StateT += dt;
            if (StateT >= RollTime) { _state = 0; IsRolling = false; }
        }

        for (int i = 0; i < Obstacles.Count; i++) { var o = Obstacles[i]; o.Z -= dz; Obstacles[i] = o; }
        for (int i = 0; i < Coins.Count; i++) { var c = Coins[i]; c.Z -= dz; Coins[i] = c; }
        for (int i = 0; i < PowerUps.Count; i++) { var p = PowerUps[i]; p.Z -= dz; PowerUps[i] = p; }
        Obstacles.RemoveAll(o => o.Z < DespawnZ);
        Coins.RemoveAll(c => c.Z < DespawnZ || c.Collected);
        PowerUps.RemoveAll(p => p.Z < DespawnZ || p.Taken);

        _scoreAccum += dz * (DoubleScore ? 2 : 1);
        Score = (int)_scoreAccum;

        int newReel = (int)(_scoreAccum / ReelLength) + 1;
        if (newReel != Reel) { Reel = newReel; ReelChanged = true; }

        _rowTimer -= dt;
        if (_rowTimer <= 0) { SpawnRow(); _rowTimer = Math.Max(0.7, 13 / ScrollSpeed); }
        _coinTimer -= dt;
        if (_coinTimer <= 0) { SpawnCoins(); _coinTimer = 1.4 + _rng.NextDouble() * 1.2; }
        _powerTimer -= dt;
        if (_powerTimer <= 0) { SpawnPowerUp(); _powerTimer = 16 + _rng.NextDouble() * 8; }

        UpdateCoins(dt);

        for (int i = PowerUps.Count - 1; i >= 0; i--)
        {
            var p = PowerUps[i];
            if (p.Taken) continue;
            if (Math.Abs(p.Z) < PickupR && Math.Abs(p.X - PlayerX) < PickupR &&
                Math.Abs(PowerY - (PlayerY + PlayerMidH)) < PickupYR)
            {
                p.Taken = true; PowerUps[i] = p;
                if (p.Kind == PowerUpKind.Magnet) _magnetUntil = _elapsedMs + PowerDurationMs;
                else _multiplierUntil = _elapsedMs + PowerDurationMs;
                PowerUps.RemoveAt(i);
            }
        }

        CheckCollisions();
    }

    private void SpawnRow()
    {
        double twoChance = Math.Min(0.75, 0.45 + 0.05 * (Reel - 1));
        int blockedCount = _rng.NextDouble() < twoChance ? 2 : 1;
        var lanes = new List<int> { 0, 1, 2 }.OrderBy(_ => _rng.NextDouble()).Take(blockedCount);
        foreach (int lane in lanes)
        {
            double roll = _rng.NextDouble();
            var kind = roll < 0.38 ? ObstacleKind.Barrier
                     : roll < 0.68 ? ObstacleKind.Overhead
                     : ObstacleKind.Train;
            double depth = kind == ObstacleKind.Train ? TrainDepth : ObstacleDepth;
            Obstacles.Add(new Obstacle { Lane = lane, Z = SpawnZ, Kind = kind, Depth = depth });
        }
    }

    private void SpawnCoins()
    {
        int count = 6 + _rng.Next(4);
        int pattern = _rng.Next(3);
        if (pattern == 0)
        {
            int lane = _rng.Next(3);
            double x = LaneX[lane];
            for (int i = 0; i < count; i++)
                Coins.Add(new Coin { X = x, Y = CoinY, Z = SpawnZ - 2 + i * CoinGap });
        }
        else if (pattern == 1)
        {
            int dir = _rng.Next(2) == 0 ? 1 : -1;
            int start = dir == 1 ? 0 : 2;
            for (int i = 0; i < count; i++)
            {
                double t = count > 1 ? (double)i / (count - 1) : 0;
                int lane = Math.Max(0, Math.Min(2, start + dir * (i * 2 / Math.Max(1, count - 1))));
                double y = CoinY + (2 - CoinY) * Math.Sin(Math.PI * t);
                Coins.Add(new Coin { X = LaneX[lane], Y = y, Z = SpawnZ - 2 + i * CoinGap });
            }
        }
        else
        {
            for (int i = 0; i < count; i++)
            {
                int lane = i % 2 == 0 ? 0 : 2;
                Coins.Add(new Coin { X = LaneX[lane], Y = CoinY, Z = SpawnZ - 2 + i * CoinGap });
            }
        }
    }

    private void SpawnPowerUp()
    {
        var kind = _rng.Next(2) == 0 ? PowerUpKind.Magnet : PowerUpKind.Multiplier;
        int lane = _rng.Next(3);
        PowerUps.Add(new PowerUp { X = LaneX[lane], Z = SpawnZ - 2, Kind = kind });
    }

    private void UpdateCoins(double dt)
    {
        double targetY = PlayerY + PlayerMidH;
        for (int i = 0; i < Coins.Count; i++)
        {
            var c = Coins[i];
            if (c.Collected) continue;
            if (MagnetActive)
            {
                double dxm = PlayerX - c.X, dzc = -c.Z;
                double dist = Math.Sqrt(dxm * dxm + dzc * dzc);
                if (dist < MagnetRadius && dist > 0.01)
                {
                    double pull = MagnetPull * dt;
                    c.X += dxm / dist * pull;
                    c.Z += dzc / dist * pull;
                    double dy = targetY - c.Y;
                    c.Y += Math.Max(-pull, Math.Min(pull, dy));
                    Coins[i] = c;
                }
            }
            if (Math.Abs(c.Z) < CollectR && Math.Abs(c.X - PlayerX) < CollectR &&
                Math.Abs(c.Y - targetY) < CollectYR)
            {
                c.Collected = true; Coins[i] = c;
                CoinsCollected++;
            }
        }
    }

    private void CheckCollisions()
    {
        if (_elapsedMs < _invincibleUntil) return;
        foreach (var o in Obstacles)
        {
            if (Math.Abs(PlayerX - LaneX[o.Lane]) >= LaneTolerance) continue;
            bool hit = o.Kind switch
            {
                ObstacleKind.Barrier => Math.Abs(o.Z) < CollideZ && PlayerY <= BarrierClearH,
                ObstacleKind.Overhead => Math.Abs(o.Z) < CollideZ && !IsRolling,
                ObstacleKind.Train => o.Z >= -1 && o.Z <= o.Depth,
                _ => false,
            };
            if (hit) { GameOver = true; return; }
        }
    }
}
