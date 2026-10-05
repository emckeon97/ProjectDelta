using Microsoft.Maui.Storage;
using SkiaSharp;
using SkiaSharp.Views.Maui;
using SkiaSharp.Views.Maui.Controls;
using PierPressure.Windows.Characters;
using PierPressure.Windows.Game;
using PierPressure.Windows.Services;

namespace PierPressure.Windows.Views;

/// <summary>
/// The run itself: 60fps 3D renderer, swipe to steer.
/// Swipe left/right = lane, up = jump, down = roll (mouse-drag works too).
/// </summary>
public partial class GamePage : ContentPage
{
    private readonly DeltaEngine _engine = new();
    private readonly Dictionary<string, SKBitmap> _sprites = new();
    private readonly string _characterId;
    private IDispatcherTimer? _loop;
    private DateTime _lastTick;
    private bool _overFired;
    private bool _wasAirborne;

    // Swipe tracking (touch press → release).
    private SKPoint _pressPoint;
    private bool _pressing;

    // Animation juice.
    private double _speedU;
    private double _lastDist;
    private double _tSec;

    public GamePage()
    {
        InitializeComponent();
        _characterId = CharacterService.Shared.SelectedId;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _ = LoadSpritesAsync();
        MusicService.Shared.Play();
        _engine.Reset();
        _lastTick = DateTime.UtcNow;
        _overFired = false;
        _wasAirborne = false;
        _lastDist = 0;
        DeltaRenderer.LandT = 1;
        _loop?.Stop();
        _loop = Dispatcher.CreateTimer();
        _loop.Interval = TimeSpan.FromSeconds(1.0 / 60.0);
        _loop.Tick += OnTick;
        _loop.Start();
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        _loop?.Stop();
        _loop = null;
        foreach (var b in _sprites.Values) b.Dispose();
        _sprites.Clear();
    }

    private async Task LoadSpritesAsync()
    {
        foreach (var id in Characters.Roster.All.Select(c => c.Id))
        {
            try
            {
                using var stream = await FileSystem.OpenAppPackageFileAsync($"{id}.png");
                var bmp = SKBitmap.Decode(stream);
                if (bmp != null) _sprites[id] = bmp;
            }
            catch { /* fallback silhouette */ }
        }
    }

    private void OnTick(object? sender, EventArgs e)
    {
        var now = DateTime.UtcNow;
        double dtMs = Math.Min(50, (now - _lastTick).TotalMilliseconds);
        _lastTick = now;

        if (!_engine.GameOver && !_engine.Paused)
        {
            _overFired = false;
            _engine.Update(dtMs);
            _tSec += dtMs / 1000.0;

            // Reel title card.
            if (_engine.ReelChanged)
            {
                _engine.ReelChanged = false;
                ShowReelCard(_engine.Reel);
            }

            // Speed + animation juice (mirrors Android).
            double d = _engine.Distance;
            if (dtMs > 0)
                _speedU = Math.Max(0, Math.Min(30, (d - _lastDist) / (dtMs / 1000.0)));
            _lastDist = d;

            double dtSec = dtMs / 1000.0;
            double lateral = DeltaEngine.LaneX[_engine.PlayerLane] - _engine.PlayerX;
            double targetLean = Math.Max(-0.3, Math.Min(0.3, lateral * 0.15));
            DeltaRenderer.Lean += (targetLean - DeltaRenderer.Lean) * Math.Min(1, dtSec * 10);

            bool airborne = _engine.PlayerY > 0.02;
            if (_wasAirborne && !airborne && !_engine.IsRolling)
                DeltaRenderer.LandT = 0;
            _wasAirborne = airborne;
            if (DeltaRenderer.LandT < 0.22) DeltaRenderer.LandT += dtSec;
        }
        else if (_engine.GameOver && !_overFired)
        {
            _overFired = true;
            var svc = CharacterService.Shared;
            int finalScore = _engine.Score;
            int finalCoins = _engine.CoinsCollected;
            bool wasRecord = finalScore > svc.HighScore && finalScore > 0;
            svc.RecordScore(finalScore);
            svc.AddCoins(finalCoins);
            Dispatcher.DispatchDelayed(TimeSpan.FromSeconds(0.6), async () =>
            {
                await Navigation.PushAsync(new GameOverPage(finalScore, finalCoins, wasRecord));
                Navigation.RemovePage(this);
            });
        }

        ScoreLabel.Text = $"{_engine.Score} m";
        CoinLabel.Text = $"🪙 {_engine.CoinsCollected}";
        Canvas.InvalidateSurface();
    }

    private async void ShowReelCard(int reel)
    {
        ReelTitle.Text = Characters.Roster.ReelTitle(reel);
        ReelBlurb.Text = Characters.Roster.ReelBlurb(reel);
        ReelCard.IsVisible = true;
        await Task.Delay(2200);
        ReelCard.IsVisible = false;
    }

    private void OnPaintSurface(object? sender, SKPaintSurfaceEventArgs e)
    {
        var canvas = e.Surface.Canvas;
        canvas.Clear(SKColors.Black);
        DeltaRenderer.Draw(canvas, _engine, _sprites, _characterId,
            _tSec, _speedU, e.Info.Width, e.Info.Height);
    }

    private void OnTouch(object? sender, SKTouchEventArgs e)
    {
        switch (e.ActionType)
        {
            case SKTouchAction.Pressed:
                _pressPoint = e.Location;
                _pressing = true;
                e.Handled = true;
                break;
            case SKTouchAction.Released when _pressing:
                _pressing = false;
                var dx = e.Location.X - _pressPoint.X;
                var dy = e.Location.Y - _pressPoint.Y;
                if (Math.Abs(dx) < 24 && Math.Abs(dy) < 24)
                {
                    // Tap = jump (quick hop).
                    _engine.Jump();
                }
                else if (Math.Abs(dx) > Math.Abs(dy))
                {
                    if (dx > 0) _engine.MoveRight(); else _engine.MoveLeft();
                }
                else
                {
                    if (dy < 0) _engine.Jump(); else _engine.Roll();
                }
                e.Handled = true;
                break;
            case SKTouchAction.Cancelled:
                _pressing = false;
                break;
        }
    }

    private void OnPauseClicked(object? sender, EventArgs e)
    {
        _engine.Paused = !_engine.Paused;
        PauseButton.Text = _engine.Paused ? "▶" : "⏸";
    }
}
