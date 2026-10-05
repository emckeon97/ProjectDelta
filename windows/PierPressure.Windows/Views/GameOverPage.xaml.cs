using Microsoft.Maui.Controls.Shapes;
using PierPressure.Windows.Services;
using PierPressure.Windows.Theme;

namespace PierPressure.Windows.Views;

/// <summary>Silent-film "THE END" card with distance, coins, best, retry.</summary>
public partial class GameOverPage : ContentPage
{
    private readonly int _score;
    private readonly int _coins;
    private readonly List<Ellipse> _lights = new();
    private IDispatcherTimer? _lightTimer;
    private int _phase;

    public GameOverPage(int score, int coins, bool isRecord)
    {
        InitializeComponent();
        _score = score;
        _coins = coins;

        var svc = CharacterService.Shared;

        ScoreLabel.Text = $"{score} m";
        CoinLine.Text = $"🪙 +{coins} coins";
        BestLine.Text = $"BEST {Math.Max(score, svc.HighScore)} m";
        RecordLabel.IsVisible = isRecord;

        for (int i = 0; i < 14; i++)
        {
            var dot = new Ellipse { WidthRequest = 7, HeightRequest = 7, Fill = DeltaTheme.GoldM };
            _lights.Add(dot);
            LightsRow.Add(dot);
        }
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        _lightTimer?.Stop();
        _lightTimer = Dispatcher.CreateTimer();
        _lightTimer.Interval = TimeSpan.FromSeconds(0.3);
        _lightTimer.Tick += (_, _) =>
        {
            _phase = (_phase + 1) % 3;
            for (int i = 0; i < _lights.Count; i++)
                _lights[i].Opacity = (i + _phase) % 3 == 0 ? 0.22 : 1.0;
        };
        _lightTimer.Start();
    }

    protected override void OnDisappearing()
    {
        base.OnDisappearing();
        _lightTimer?.Stop();
    }

    private async void OnRetryClicked(object? sender, EventArgs e)
    {
        await Navigation.PushAsync(new GamePage());
        Navigation.RemovePage(this);
    }

    private async void OnMenuClicked(object? sender, EventArgs e)
        => await Navigation.PopToRootAsync();
}
