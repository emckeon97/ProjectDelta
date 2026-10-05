using Microsoft.Maui.Storage;
#if WINDOWS
using Windows.Media.Core;
using Windows.Media.Playback;
#endif

namespace PierPressure.Windows.Services;

/// <summary>
/// Background music: "The Entertainer" (Kevin MacLeod, CC-BY 4.0).
/// Safe no-op if the MP3 isn't bundled.
/// </summary>
public sealed class MusicService
{
    public static MusicService Shared { get; } = new();

    private const string MutedKey = "delta.musicMuted";

    public bool IsMuted
    {
        get => Preferences.Default.Get(MutedKey, false);
        private set => Preferences.Default.Set(MutedKey, value);
    }

    public event Action? MuteChanged;

#if WINDOWS
    private MediaPlayer? _player;

    private MediaPlayer? EnsurePlayer()
    {
        if (_player != null) return _player;
        try
        {
            var path = Path.Combine(AppContext.BaseDirectory, "delta_ragtime.mp3");
            if (!File.Exists(path)) return null;
            _player = new MediaPlayer
            {
                Source = MediaSource.CreateFromUri(new Uri(path)),
                Volume = 0.45,
                IsLoopingEnabled = true,
            };
            return _player;
        }
        catch { return null; }
    }
#endif

    public void Play()
    {
        if (IsMuted) return;
#if WINDOWS
        try { EnsurePlayer()?.Play(); } catch { }
#endif
    }

    public void Pause()
    {
#if WINDOWS
        try { _player?.Pause(); } catch { }
#endif
    }

    public void ToggleMute()
    {
        IsMuted = !IsMuted;
        if (IsMuted) Pause(); else Play();
        MuteChanged?.Invoke();
    }
}
