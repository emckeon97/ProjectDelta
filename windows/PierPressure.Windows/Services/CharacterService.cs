using Microsoft.Maui.Storage;
using PierPressure.Windows.Characters;

namespace PierPressure.Windows.Services;

/// <summary>
/// Coin wallet, high score, selected character, and unlocks — persisted
/// via MAUI Preferences (same keys as the mobile ports).
/// </summary>
public sealed class CharacterService
{
    public static CharacterService Shared { get; } = new();

    private const string CoinsKey = "delta.coins";
    private const string HighKey = "delta.highScore";
    private const string SelectedKey = "delta.selected";
    private const string UnlockedKey = "delta.unlocked"; // comma-separated ids

    public int Coins => Preferences.Default.Get(CoinsKey, 0);
    public int HighScore => Preferences.Default.Get(HighKey, 0);

    public string SelectedId
    {
        get => Preferences.Default.Get(SelectedKey, "popeye");
        set => Preferences.Default.Set(SelectedKey, value);
    }

    public event Action? Changed;

    public bool IsUnlocked(string id)
    {
        var c = Roster.ById(id);
        if (c == null) return false;
        if (c.Price == 0) return true;
        var set = UnlockedSet();
        return set.Contains(id);
    }

    public bool Unlock(string id)
    {
        var c = Roster.ById(id);
        if (c == null || IsUnlocked(id) || Coins < c.Price) return false;
        Preferences.Default.Set(CoinsKey, Coins - c.Price);
        var set = UnlockedSet();
        set.Add(id);
        Preferences.Default.Set(UnlockedKey, string.Join(",", set));
        Changed?.Invoke();
        return true;
    }

    public void AddCoins(int n)
    {
        Preferences.Default.Set(CoinsKey, Coins + n);
        Changed?.Invoke();
    }

    public void RecordScore(int score)
    {
        if (score > HighScore)
            Preferences.Default.Set(HighKey, score);
        Changed?.Invoke();
    }

    private HashSet<string> UnlockedSet()
    {
        var raw = Preferences.Default.Get(UnlockedKey, "");
        return new HashSet<string>(raw.Split(',', StringSplitOptions.RemoveEmptyEntries));
    }
}
