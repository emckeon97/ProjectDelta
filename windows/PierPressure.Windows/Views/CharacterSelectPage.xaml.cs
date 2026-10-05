using System.Collections.ObjectModel;
using Microsoft.Maui.Storage;
using PierPressure.Windows.Characters;
using PierPressure.Windows.Services;
using PierPressure.Windows.Theme;

namespace PierPressure.Windows.Views;

public partial class CharacterSelectPage : ContentPage
{
    private sealed class ToonRow
    {
        public string Id { get; set; } = "";
        public string Name { get; set; } = "";
        public string PriceText { get; set; } = "";
        public ImageSource? Image { get; set; }
        public bool Unlocked { get; set; }
        public bool Selected { get; set; }
    }

    private readonly ObservableCollection<ToonRow> _rows = new();

    public CharacterSelectPage()
    {
        InitializeComponent();
        RosterView.ItemsSource = _rows;
        CharacterService.Shared.Changed += Refresh;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        Refresh();
    }

    private void Refresh()
    {
        var svc = CharacterService.Shared;
        CoinsLabel.Text = $"🪙 {svc.Coins} coins";
        _rows.Clear();
        foreach (var c in Roster.All)
        {
            bool unlocked = svc.IsUnlocked(c.Id);
            bool selected = svc.SelectedId == c.Id;
            var row = new ToonRow
            {
                Id = c.Id,
                Name = c.Name,
                PriceText = selected ? "★ SELECTED" : unlocked ? "TAP TO PLAY" : $"🪙 {c.Price}",
                Unlocked = unlocked,
                Selected = selected,
            };
            _rows.Add(row);
            _ = LoadSpriteAsync(c.Id, row);
        }
    }

    private static async Task LoadSpriteAsync(string id, ToonRow row)
    {
        try
        {
            var stream = await FileSystem.OpenAppPackageFileAsync($"{id}.png");
            row.Image = ImageSource.FromStream(() => stream);
        }
        catch { row.Image = null; }
    }

    private async void OnToonTapped(object? sender, EventArgs e)
    {
        if (sender is not TapGestureRecognizer tap || tap.CommandParameter is not string id)
            return;
        var svc = CharacterService.Shared;
        var c = Roster.ById(id);
        if (c == null) return;

        if (svc.IsUnlocked(id))
        {
            svc.SelectedId = id;
            Refresh();
            return;
        }
        if (svc.Coins >= c.Price)
        {
            bool ok = svc.Unlock(id);
            if (ok)
            {
                svc.SelectedId = id;
                await DisplayAlert("Encore!", $"{c.Name} joins the cast!", "OK");
            }
        }
        else
        {
            await DisplayAlert("Not enough coins",
                $"{c.Name} costs {c.Price} coins — you have {svc.Coins}. Keep running!", "OK");
        }
        Refresh();
    }

    private async void OnBackClicked(object? sender, EventArgs e)
        => await Navigation.PopAsync();
}
