using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// All sound effects synthesized in code (no audio assets needed).
/// Optional ragtime loop: place delta_ragtime.mp3 at
/// Assets/Resources/Music/delta_ragtime.mp3 — it plays if present,
/// the game is silent otherwise.
/// </summary>
public class AudioSynth : MonoBehaviour
{
    public static AudioSynth Instance { get; private set; }

    private AudioSource sfxSource;
    private AudioSource musicSource;
    private readonly Dictionary<string, AudioClip> clips = new Dictionary<string, AudioClip>();

    private const int SampleRate = 22050;

    void Awake()
    {
        Instance = this;

        sfxSource = gameObject.AddComponent<AudioSource>();
        sfxSource.playOnAwake = false;

        musicSource = gameObject.AddComponent<AudioSource>();
        musicSource.playOnAwake = false;
        musicSource.loop = true;

        clips["jump"] = MakeTone(300f, 700f, 0.18f, 0.5f);
        clips["coin"] = MakeCoinDing();
        clips["crash"] = MakeNoise(0.4f, 0.7f);
        clips["click"] = MakeTone(800f, 800f, 0.06f, 0.4f);
        clips["powerup"] = MakeTone(400f, 1200f, 0.25f, 0.5f);

        AudioClip music = Resources.Load<AudioClip>("Music/delta_ragtime");
        if (music != null)
        {
            musicSource.clip = music;
            musicSource.volume = 0.6f;
            musicSource.Play();
        }
    }

    public void Play(string name)
    {
        AudioClip clip;
        if (clips.TryGetValue(name, out clip) && sfxSource != null)
            sfxSource.PlayOneShot(clip);
    }

    private AudioClip MakeTone(float startFreq, float endFreq, float duration, float volume)
    {
        int samples = Mathf.CeilToInt(SampleRate * duration);
        float[] data = new float[samples];
        float phase = 0f;
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / samples;
            float freq = Mathf.Lerp(startFreq, endFreq, t);
            phase += 2f * Mathf.PI * freq / SampleRate;
            float env = Mathf.Sin(Mathf.PI * t);
            data[i] = Mathf.Sin(phase) * env * volume;
        }
        AudioClip clip = AudioClip.Create("tone", samples, 1, SampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private AudioClip MakeCoinDing()
    {
        float duration = 0.25f;
        int samples = Mathf.CeilToInt(SampleRate * duration);
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SampleRate;
            float freq = t < 0.09f ? 988f : 1319f;
            float env = Mathf.Exp(-6f * t);
            data[i] = Mathf.Sin(2f * Mathf.PI * freq * t) * env * 0.5f;
        }
        AudioClip clip = AudioClip.Create("coin", samples, 1, SampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }

    private AudioClip MakeNoise(float duration, float volume)
    {
        int samples = Mathf.CeilToInt(SampleRate * duration);
        float[] data = new float[samples];
        System.Random rng = new System.Random(12345);
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / samples;
            float env = (1f - t) * (1f - t);
            data[i] = ((float)rng.NextDouble() * 2f - 1f) * env * volume;
        }
        AudioClip clip = AudioClip.Create("noise", samples, 1, SampleRate, false);
        clip.SetData(data, 0);
        return clip;
    }
}
