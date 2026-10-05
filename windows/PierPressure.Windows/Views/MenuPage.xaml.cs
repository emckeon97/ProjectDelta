using Microsoft.Maui.Controls.Shapes;
using Microsoft.Maui.Storage;
using PierPressure.Windows.Characters;
using PierPressure.Windows.Services;
using PierPressure.Windows.Theme;

namespace PierPressure.Windows.Views;

public partial class MenuPage : ContentPage
{
    private readonly List<Ellipse> _lights = new();
    private IDispatcherTimer? _lightTimer;
    private int _phase;

    public MenuPage()
    {
        InitializeComponent();
        for (int i = 0; i < 18; i++)
        {
            var dot = new Ellipse { WidthRequest = 7, HeightRequest = 7, Fill = DeltaTheme.GoldM };
            _lights.Add(dot);
            LightsRow.Add(dot);
        }
        BillingLabel.Text = string.Join("   •   ", Roster.All.Select(c => c.Name.ToUpperInvariant()));
        Refresh();
        CharacterService.Shared.Changed += Refresh;
        MusicService.Shared.MuteChanged += RefreshMute;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        MusicService.Shared.Play();
        Refresh();
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

    private void Refresh()
    {
        var svc = CharacterService.Shared;
        var sel = Roster.ById(svc.SelectedId) ?? Roster.All[0];
        HeroName.Text = sel.Name.ToUpperInvariant();
        CoinsLabel.Text = $"🪙 {svc.Coins}";
        HighLabel.Text = $"★ {svc.HighScore} m";
        _ = LoadSpriteAsync(sel.Id);
        RefreshMute();
    }

    private async Task LoadSpriteAsync(string id)
    {
        try
        {
            var stream = await FileSystem.OpenAppPackageFileAsync($"{id}.png");
            HeroSprite.Source = ImageSource.FromStream(() => stream);
        }
        catch { HeroSprite.Source = null; }
    }

    private void RefreshMute()
        => MuteButton.Text = MusicService.Shared.IsMuted ? "🔇" : "🔊";

    private void OnMuteClicked(object? sender, EventArgs e)
        => MusicService.Shared.ToggleMute();

    private async void OnPlayClicked(object? sender, EventArgs e)
        => await Navigation.PushAsync(new GamePage());

    private async void OnStarsClicked(object? sender, EventArgs e)
        => await Navigation.PushAsync(new CharacterSelectPage());
}
